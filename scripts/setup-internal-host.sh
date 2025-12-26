#!/bin/bash
# setup-internal-host.sh - Minimal setup for reverse SSH tunnel

set -e

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <host_name> <bastion_ip> <bastion_user> <reverse_port>"
    exit 1
fi

HOST_NAME=$1
BASTION_IP=$2
BASTION_USER=$3
REVERSE_PORT=$4
LOCAL_PORT=${5:-22}

echo "--- Minimal Reverse Tunnel Setup ---"

# Install autossh if missing
if ! command -v autossh &> /dev/null; then
    echo "Installing autossh..."
    sudo apt update || echo "Warning: apt update failed, attempting install anyway..."
    sudo apt install -y autossh
fi

TUNNEL_CMD="autossh -f -M 0 -N -o \"ServerAliveInterval 30\" -o \"ServerAliveCountMax 3\" -o \"StrictHostKeyChecking accept-new\" -R ${REVERSE_PORT}:localhost:${LOCAL_PORT} ${BASTION_USER}@${BASTION_IP}"

echo "Starting tunnel..."
eval $TUNNEL_CMD

echo "SUCCESS: Tunnel started."
echo "Check on Bastion: ss -tlnp | grep ${REVERSE_PORT}"
echo ""
echo "To make this persistent after reboot, run:"
echo "(crontab -l 2>/dev/null; echo \"@reboot $TUNNEL_CMD\") | crontab -"
