#!/bin/bash

TICKET_ID=$1

response=$(curl \
  -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  -H 'Accept: application/json' \
  "${JIRA_BASE_URL}/rest/api/2/issue/${TICKET_ID}")

if echo "$response" | grep -q "\"key\":\"${TICKET_ID}\""; then
  echo "::set-output name=exists::true"
else
  echo "::set-output name=exists::false"
fi