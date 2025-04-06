#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...       ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Prompt for zone input
read -p "$(echo -e ${MAGENTA_TEXT}${BOLD_TEXT}Enter the zone:${RESET_FORMAT} ) " ZONE
export ZONE

# Create storage bucket
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID

# Copy startup script to bucket
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Copying startup script to bucket...${RESET_FORMAT}"
gsutil cp gs://cloud-training/gcpnet/auto-install-web.sh gs://$DEVSHELL_PROJECT_ID

# Create Compute Engine instance with startup script
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Compute Engine instance...${RESET_FORMAT}"
gcloud compute instances create quickgcplab \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=n1-standard-1 \
  --tags=http-server \
  --metadata startup-script-url=gs://$DEVSHELL_PROJECT_ID/auto-install-web.sh

# Add firewall rule to allow HTTP traffic
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating firewall rule to allow HTTP traffic...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --description="Allow incoming HTTP traffic" \
  --direction=INGRESS \
  --target-tags=http-server

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}     Check my GitHub: https://github.com/vinay-th      ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""

