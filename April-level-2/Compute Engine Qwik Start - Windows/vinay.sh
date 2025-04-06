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

# Step 1: Check authentication
echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${WHITE_TEXT}Checking authenticated accounts in gcloud...${RESET_FORMAT}"
gcloud auth list

# Step 2: Fetch compute zone
echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${WHITE_TEXT}Fetching default compute zone for the project...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 3: Create a Compute Engine instance
echo "${CYAN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${WHITE_TEXT}Creating a new Compute Engine instance...${RESET_FORMAT}"
gcloud compute instances create windows-instance \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --create-disk=auto-delete=yes,boot=yes,device-name=windows-instance,image=projects/windows-cloud/global/images/windows-server-2022-dc-v20230913,mode=rw,size=50,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced

# Step 4: Wait for instance to initialize
echo "${YELLOW_TEXT}${BOLD_TEXT}Please wait while the instance initializes...${RESET_FORMAT}"
sleep 30

# Step 5: Get serial port output
echo "${CYAN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${WHITE_TEXT}Fetching serial port output...${RESET_FORMAT}"
gcloud compute instances get-serial-port-output windows-instance --zone=$ZONE

# Step 6: Reset Windows password
echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${WHITE_TEXT}Resetting Windows password for user 'admin'...${RESET_FORMAT}"
gcloud compute reset-windows-password windows-instance --zone=$ZONE --user admin --quiet

# Final message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}        Check my GitHub: https://github.com/vinay-th   ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""

