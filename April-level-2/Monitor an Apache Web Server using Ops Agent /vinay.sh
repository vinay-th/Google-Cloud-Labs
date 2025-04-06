#!/bin/bash

# Define color codes for output formatting
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=$(tput setab 1)
GREEN_TEXT=$(tput setab 2)
RED_TEXT=$(tput setaf 1)

BOLD_TEXT=$(tput bold)
RESET_FORMAT=$(tput sgr0)

echo "${BACKGROUND_RED}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

# Prompt user to enter the desired compute zone
read -p "${YELLOW_COLOR}${BOLD_TEXT}Enter ZONE:${RESET_FORMAT}" ZONE

# Authenticate and configure project
gcloud auth list
export PROJECT_ID=$DEVSHELL_PROJECT_ID
gcloud config set compute/zone $ZONE

# Create a new Compute Engine instance with firewall rules
gcloud compute instances create quickstart-vm \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-small \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --tags=http-server,https-server && \
gcloud compute firewall-rules create default-allow-http \
  --target-tags=http-server \
  --allow tcp:80 \
  --description="Allow HTTP traffic" && \
gcloud compute firewall-rules create default-allow-https \
  --target-tags=https-server \
  --allow tcp:443 \
  --description="Allow HTTPS traffic"

# Create and upload setup script
cat > cp_disk.sh <<'EOF'
#!/bin/bash

sudo apt-get update && sudo apt-get install apache2 php -y

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Backup existing config and set up Ops Agent
set -e
sudo cp /etc/google-cloud-ops-agent/config.yaml /etc/google-cloud-ops-agent/config.yaml.bak

sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << EOF_INNER
metrics:
  receivers:
    apache:
      type: apache
  service:
    pipelines:
      apache:
        receivers:
          - apache
logging:
  receivers:
    apache_access:
      type: apache_access
    apache_error:
      type: apache_error
  service:
    pipelines:
      apache:
        receivers:
          - apache_access
          - apache_error
EOF_INNER

sudo service google-cloud-ops-agent restart
sleep 60
EOF

gcloud compute scp cp_disk.sh quickstart-vm:/tmp --project=$PROJECT_ID --zone=$ZONE --quiet

# SSH and execute setup script
gcloud compute ssh quickstart-vm --project=$PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/cp_disk.sh"

# Create notification channel config
cat > cp-channel.json <<EOF
{
  "type": "pubsub",
  "displayName": "channel-display-name",
  "description": "demo subscription channel",
  "labels": {
    "topic": "projects/$PROJECT_ID/topics/notificationTopic"
  }
}
EOF

gcloud beta monitoring channels create --channel-content-from-file=cp-channel.json

email_channel=$(gcloud beta monitoring channels list)
channel_id=$(echo "$email_channel" | grep -oP 'name: \K[^ ]+' | head -n 1)

# Create alert policy JSON
cat > stopped-vm-alert-policy.json <<EOF
{
  "displayName": "Apache traffic above threshold",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - workload/apache.traffic",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"workload.googleapis.com/apache.traffic\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 4000
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "1800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF

gcloud alpha monitoring policies create --policy-from-file=stopped-vm-alert-policy.json

# Completion message
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Check out my GitHub: https://github.com/vinay-th${RESET_FORMAT}"
