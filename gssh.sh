#!/bin/bash
# gssh.sh - A wrapper to SSH into GCP instances while handling dynamic host keys

INSTANCE_NAME=$1
ZONE=${2:-"asia-east1-a"}

if [ -z "$INSTANCE_NAME" ]; then
    echo "Usage: ./gssh.sh [INSTANCE_NAME] [ZONE]"
    exit 1
fi

echo "Connecting to $INSTANCE_NAME in $ZONE..."

# Use gcloud with flags to ignore host key checking and skip writing to known_hosts
gcloud compute ssh "$INSTANCE_NAME" \
    --zone "$ZONE" \
    --tunnel-through-iap \
    -- -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel=ERROR"
