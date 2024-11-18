#!/bin/bash

# Exit script on error
set -e

# Define the configuration file
CONFIG_FILE="deploy_config.yaml"
ORIGINAL_DIR="$(pwd)"

# Function to log messages
log_message() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

# Check if yq is installed (used for parsing YAML)
if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed. Please install yq to use this script."
  exit 1
fi

# Log start of the script
log_message "Script started."

# Step 1: Parse configuration file for repo details
log_message "Reading configuration file: $CONFIG_FILE"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Configuration file $CONFIG_FILE not found."
  exit 1
fi

REPO_URL=$(yq '.repository.url' "$CONFIG_FILE")
BRANCH_NAME=$(yq '.repository.branch' "$CONFIG_FILE")
ENV_VARS=$(yq '.environment' "$CONFIG_FILE")

# Validate necessary fields
if [[ -z "$REPO_URL" || -z "$BRANCH_NAME" ]]; then
  echo "Error: Missing 'repository.url' or 'repository.branch' in the configuration file."
  exit 1
fi

# Extract the repo folder name
REPO_NAME=$(basename -s .git "$REPO_URL")

# Step 2: Clone the repository if not already cloned
if [[ ! -d "$REPO_NAME" ]]; then
  log_message "Cloning repository $REPO_URL."
  git clone "$REPO_URL"
  log_message "Repository cloned successfully."
else
  log_message "Repository $REPO_NAME already exists. Skipping cloning."
fi

# Step 3: Change to the repo directory and set up the branch
cd "$REPO_NAME"
log_message "Switched to repository folder: $REPO_NAME"

log_message "Checking out or creating branch: $BRANCH_NAME."
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
fi

log_message "Pulling latest changes for branch: $BRANCH_NAME."
git pull origin "$BRANCH_NAME"
log_message "Branch is up-to-date."

# Step 4: Run Docker Compose command with environment variables from YAML
cd "$ORIGINAL_DIR"
log_message "Preparing environment variables for Docker Compose."
ENV_FILE=".env.generated"

# Generate environment file from YAML configuration
log_message "Generating environment variables file: $ENV_FILE."
ENV_CONTENT=$(yq -r '.environment | to_entries | map("\(.key)=\(.value)") | .[]' "$CONFIG_FILE")
if [[ $? -ne 0 || -z "$ENV_CONTENT" ]]; then
  echo "Error: Failed to generate environment variables from YAML configuration."
  exit 1
fi
echo "$ENV_CONTENT" > "$ENV_FILE"
log_message "Environment variables written to $ENV_FILE."

# Run Docker Compose
DOCKER_COMPOSE_COMMAND="docker compose -f $REPO_NAME/deploy/docker-compose.yml --env-file $ENV_FILE up --build -d"
log_message "Executing Docker Compose: $DOCKER_COMPOSE_COMMAND"
eval "$DOCKER_COMPOSE_COMMAND"

# Run Laravel migrations
log_message "Running Laravel migrations using Docker."
DOCKER_EXEC_COMMAND="docker exec -t laravelapp php artisan migrate"
if eval "$DOCKER_EXEC_COMMAND"; then
  log_message "Laravel migrations ran successfully."
else
  echo "Error: Failed to run Laravel migrations."
  exit 1
fi

# Clean up the generated .env file
rm -f "$ENV_FILE"
log_message "Cleaned up temporary environment file."

# End of the script
log_message "Script completed successfully."
