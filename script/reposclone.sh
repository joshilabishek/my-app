#!/bin/bash
# Replace with your GitHub username and organization name
GITHUB_USERNAME="Sherin-CB"
ORGANIZATION_NAME="Connected2FiberTeam"
# Replace with your personal access token (PAT)
# Generate one at https://github.com/settings/tokens
ACCESS_TOKEN="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"
# API endpoint to fetch repositories
API_URL="https://api.github.com/orgs/${ORGANIZATION_NAME}/repos"
# Function to fetch repositories using GitHub API
function fetch_repositories() {
  local page="$1"
  local repos=$(curl -s -H "Authorization: token ${ACCESS_TOKEN}" "${API_URL}?page=${page}&per_page=100" | jq -r '.[].name')
  # Iterate through repositories and clone them
  for repo in $repos; do
    echo "Cloning repository: ${repo}"
    expect -c "
      spawn git clone --quiet \"https://github.com/${ORGANIZATION_NAME}/${repo}.git\" \"${repo}\"
      expect \"Username for 'https://github.com':\" { send \"${GITHUB_USERNAME}\r\" }
      expect \"Password for 'https://${GITHUB_USERNAME}@github.com':\" { send \"${ACCESS_TOKEN}\r\" }
      interact
    "
  done
}
# Create a directory to store the downloaded repositories
mkdir -p "${ORGANIZATION_NAME}"
cd "${ORGANIZATION_NAME}"
# Fetch and clone repositories using pagination
page=1
while true; do
  echo "Fetching page: ${page}"
  fetch_repositories "${page}"
  link_header=$(curl -s -I -H "Authorization: token ${ACCESS_TOKEN}" "${API_URL}?page=${page}&per_page=100" | grep -i "Link:" | tr -d '\r')
  if [[ "$link_header" =~ page=([0-9]+) ]]; then
    page="${BASH_REMATCH[1]}"
  else
    break
  fi
done
echo "All repositories cloned successfully."
