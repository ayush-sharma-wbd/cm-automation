#!/bin/bash

# ensure Jira secrets are available
if [[ "$JIRA_USER_EMAIL" == "" || "$JIRA_API_TOKEN" == "" || "$JIRA_BASE_URL" == "" ]]; then
  echo "::error::script requires the following env vars to be exported: JIRA_USER_EMAIL, JIRA_API_TOKEN, JIRA_BASE_URL"
  exit 1
fi

# ensure inputs are correct
if [[ $# -ne 1 ]]; then
  echo "::error::script given $# positional parameters when 1 is required: <ticket ID>"
  exit 1
fi
TICKET_ID=$1

EXISTS=false
PROJECT_ID=
if [[ "$TICKET_ID" =~ ^[a-zA-Z]+-[0-9]+$ ]]; then
  output_json=$(mktemp)
  status_code=$(
    curl --silent \
      -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" \
      -H 'Accept: application/json' \
      -o "$output_json" -w '%{http_code}' \
      "$JIRA_BASE_URL/rest/api/2/issue/$TICKET_ID"
  )
  if [[ $status_code -eq 200 ]]; then
    EXISTS=true
    PROJECT_ID=$(jq --raw-output '.fields.project.id' "$output_json")
  else
    # TODO check for expected (error) status code: 404; and in the case of an unexpected code: error out
    echo "::warn::the ticket \"$TICKET_ID\" was not accessible on the \"$JIRA_BASE_URL\" Jira instance"
    return 1
  fi
else
  echo "::warn::the given input for ticket ID: \"$TICKET_ID\" does not match the expected format, e.g. \"GROUP-##\""
  exit 1
fi

echo "exists=$EXISTS" | tee -a "$GITHUB_OUTPUT"
echo "project-id=$PROJECT_ID" | tee -a "$GITHUB_OUTPUT"
