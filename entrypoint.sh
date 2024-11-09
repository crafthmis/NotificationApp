#!/bin/bash
set -e
# Install jq if not already installed (use sudo for apt-get commands)
if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Function to read environment variables from env.json
read_env_json() {
    local env=${ENVIRONMENT:-development}
    if [[ -f /app/config/env.json ]]; then
        eval $(jq -r ".$env | to_entries | map(\"export \(.key)='\(.value|tostring)'\") | .[]" /app/config/env.json)
        echo "Environment variables set from env.json for $env environment"
    else
        echo "env.json file not found"
    fi
}

# Read environment variables
read_env_json

# Print environment variables for debugging
echo "Using the following database configuration:"
echo "POSTGRES_DB: $POSTGRES_DB"
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_PORT: $POSTGRES_PORT"
echo "POSTGRES_HOST: $POSTGRES_HOST"

# Run the original entrypoint script
exec docker-entrypoint.sh "$@"
