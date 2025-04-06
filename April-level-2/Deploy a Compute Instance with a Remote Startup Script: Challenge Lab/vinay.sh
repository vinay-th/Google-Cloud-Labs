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

# Create a unique bucket name (if re-run)
BUCKET_NAME="${DEVSHELL_PROJECT_ID}-web-script-bucket"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb -l $ZONE gs://$BUCKET_NAME

# Copy remote startup script to your bucket
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Copying install-web.sh startup script to bucket...${RESET_FORMAT}"
gsutil cp gs://spls/gsp301/install-web.sh gs://$BUCKET_NAME/

# Create Compute Engine instance with the startup script
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating Compute Engine instance (quickgcplab)...${RESET_FORMAT}"
gcloud compute instances create quickgcplab \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --tags=http-server \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --metadata startup-script-url=gs://$BUCKET_NAME/install-web.sh

# Add firewall rule (skip error if it already exists)
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating firewall rule to allow HTTP traffic...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --description="Allow incoming HTTP traffic" \
  --direction=INGRESS \
  --target-tags=http-server 2>/dev/null || echo "${YELLOW_TEXT}Firewall rule already exists. Skipping...${RESET_FORMAT}"

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}     Check my GitHub: https://github.com/vinay-th      ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
