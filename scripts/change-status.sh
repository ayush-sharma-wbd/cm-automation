#!/bin/bash

TICKET_ID=$1

# Change Transition Status 
response=$(curl \
  -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  -X POST --data '{"transition":{"id":"31"}}' \
  -H 'Accept: application/json' \
  "${JIRA_BASE_URL}/rest/api/2/issue/${TICKET_ID}/transitions")

# Get Transitions
response=$(curl \
  -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  -H 'Accept: application/json' \
  "${JIRA_BASE_URL}/rest/api/2/issue/${TICKET_ID}/transitions")

# if echo "$response" | grep -q "\"key\":\"${TICKET_ID}\""; then
#   echo "::set-output name=exists::true"
# else
#   echo "::set-output name=exists::false"
# fi

echo "$response"