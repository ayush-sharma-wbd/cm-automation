#!/bin/bash

# Ensure Jira Secrets Are Available
if [[ "$JIRA_USER_EMAIL" == "" || "$JIRA_API_TOKEN" == "" || "$JIRA_BASE_URL" == "" ]]; then
  echo "::error::script requires the following env vars to be exported: JIRA_USER_EMAIL, JIRA_API_TOKEN, JIRA_BASE_URL"
  exit 1
fi

# Ensure Number Of Paramters Passed In The Script Are Correct
if [[ $# -ne 1 ]]; then
  echo "::error::script given $# positional parameters when 2 are required: <ticket ID> "
  exit 1
fi

TICKET_ID=$1

# Check If Ticket Exists
response=$(curl -s -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  -X GET -H 'Accept: application/json' \
  "${JIRA_BASE_URL}/rest/api/2/issue/${TICKET_ID}")

error_message=$(echo "$response" | jq -r '.errorMessages[0] // empty')

if [[ -n "$error_message" ]]; then
  echo "Error: $error_message"
  exit 1
fi

# Fetch Status Of Ticket 
ticket_status_response=$(curl \
  -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  -X GET \
  -H 'Accept: application/json' \
  "${JIRA_BASE_URL}/rest/api/2/issue/${TICKET_ID}?fields=status" | jq . )

echo "$ticket_status_response"

# Check if the status name is "Change Approved"
status_name=$(echo "$response" | jq -r '.fields.status.name')

if [[ "$status_name" == "Change Approved" ]]; then
  echo "The CMR Ticket Is Approved. Transitioning It Into In Progress Mode ..."
  transition_resp=$(curl -u $JIRA_USER_EMAIL:$JIRA_API_TOKEN -X POST --data '{"transition":{"id":"71"}}' -H "Content-Type: application/json" "$JIRA_BASE_URL/rest/api/2/issue/$TICKET_ID/transitions" | jq .)  
  echo $transition_resp
  echo "Transition Successfull"
else
  echo "The CMR Ticket Is Not Approved."
  exit 1
fi