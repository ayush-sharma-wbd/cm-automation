#!/bin/bash

# Ensure Jira Secrets Are Available
if [[ -z "$JIRA_USER_EMAIL" || -z "$JIRA_API_TOKEN" || -z "$JIRA_BASE_URL" ]]; then
  echo "::error::script requires the following env vars to be exported: JIRA_USER_EMAIL, JIRA_API_TOKEN, JIRA_BASE_URL"
  exit 1
fi

# Ensure Number Of Parameters Passed In The Script Are Correct
if [[ $# -ne 2 ]]; then
  echo "::error::script given $# positional parameters when 2 are required: <ticket ID> <rollback FLAG>"
  exit 1
fi

TICKET_ID=$1
ROLLBACK_FLAG=$2

# 1 denotes Rollback
echo "::info::Rollback Flag = $ROLLBACK_FLAG"

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

  if [[ "$ROLLBACK_FLAG" == "false" ]]; then
    if [[ "$status_name" == "Change Approved" ]]; then
      echo "::info::The CM Ticket Is In Approved State. Transitioning It Into In Progress Mode ..."

      transition_output_json=$(mktemp)
      transition_status_code=$(curl --silent -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" \
        -X POST \
        --data '{"transition":{"id":"71"}}' \
        -H "Content-Type: application/json" \
        -o "$transition_output_json" -w '%{http_code}' \
        "$JIRA_BASE_URL/rest/api/2/issue/$TICKET_ID/transitions")

      if [[ $transition_status_code -eq 204 ]]; then
        echo "::info::Transition Successful !!"
      else
        echo "::error::Transitioning status of the ticket \"$TICKET_ID\" failed with status code $transition_status_code."
        exit 1
      fi
    elif [[ "$status_name" == "In Progress" ]]; then
      echo "::info::The CM Ticket is already in In Progress Mode."
    else
      echo "::error::The CM Ticket Is Not In Approved State. Please Check !!"
      exit 1
    fi
  else
    if [[ "$status_name" == "In Progress" || "$status_name" == "Live Checks" || "$status_name" == "Done" ]]; then
      echo "::info::The CM ticket is in an appropriate state for the current operation. Current state: $status_name."
      # If Transition Needed, To Be Added Here ...
    else
      echo "::warning::The CM ticket is not in a state suitable for the current operation. Current state: $status_name. Please verify the ticket's state."
    fi
  fi
else
  echo "::error::Fetching status of the ticket \"$TICKET_ID\" failed with status code $status_code."
  exit 1
fi