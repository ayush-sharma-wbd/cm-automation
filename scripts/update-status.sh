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

source ./check-ticket.sh $TICKET_ID
exit_code=$?

# If Ticket Does'nt Exist
if [ $exit_code -ne 0 ]; then
  echo "Inner script failed with exit_code $exit_code. Exiting."
  exit 1
fi

# Fetch Status Of Ticket 
output_json=$(mktemp)
status_code=$(curl --silent \
  -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  -X GET \
  -H 'Accept: application/json' \
  -o "$output_json" -w '%{http_code}' \
  "${JIRA_BASE_URL}/rest/api/2/issue/${TICKET_ID}?fields=status")

# Check if the status code is 200
if [[ $status_code -eq 200 ]]; then
  # Extract the status name from the JSON response
  status_name=$(jq -r '.fields.status.name' "$output_json")

  if [[ "$status_name" == "Change Approved" ]]; then
    echo "The CMR Ticket Is In Approved State. Transitioning It Into In Progress Mode ..."
    transition_output_json=$(mktemp)
    transition_status_code=$(curl --silent -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" \
      -X POST \
      --data '{"transition":{"id":"71"}}' \
      -H "Content-Type: application/json" \
      -o "$transition_output_json" -w '%{http_code}' \
      "$JIRA_BASE_URL/rest/api/2/issue/$TICKET_ID/transitions")

    if [[ $transition_status_code -eq 204 ]]; then
      echo "Transition Successfull !!"
    else
      echo "::error::Transitioning status of the ticket \"$TICKET_ID\" failed with status code $transition_status_code."
      exit 1      
    fi
  else
    echo "The CMR Ticket Is Not In Approved State. Please Check !!"
    exit 1
  fi
else
  echo "::error::Fetching status of the ticket \"$TICKET_ID\" failed with status code $status_code."
  exit 1
fi