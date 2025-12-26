#!/bin/bash
# setup-internal-host.sh - Sets up a reverse SSH tunnel service on an internal host

set -e

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <host_name> <bastion_ip> <bastion_user> <reverse_port> [local_port]"
    echo "Example: $0 host-a 1.2.3.4 bastionuser 2201 22"
    exit 1
fi

HOST_NAME=$1
BASTION_IP=$2
BASTION_USER=$3
REVERSE_PORT=$4
LOCAL_PORT=${5:-22}
SERVICE_NAME="reverse-ssh-${HOST_NAME}"

echo "Setting up reverse tunnel for ${HOST_NAME} on port ${REVERSE_PORT}..."

# Install autossh if missing
if ! command -v autossh &> /dev/null; then
    echo "Installing autossh..."
    sudo apt update && sudo apt install -y autossh
fi

# Create systemd service file
cat <<EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=Reverse SSH tunnel (${HOST_NAME} -> bastion)
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=/usr/bin/autossh -M 0 -N \\
  -o "ExitOnForwardFailure=yes" \\
  -o "ServerAliveInterval=30" \\
  -o "ServerAliveCountMax=3" \\
  -o "StrictHostKeyChecking=accept-new" \\
  -R 127.0.0.1:${REVERSE_PORT}:localhost:${LOCAL_PORT} \\
  ${BASTION_USER}@${BASTION_IP}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload, enable and start
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl start "${SERVICE_NAME}"

echo "Service ${SERVICE_NAME} created and enabled."
echo "To start it: sudo systemctl start ${SERVICE_NAME}"
echo ""
echo "IMPORTANT: Ensure this host's SSH public key is added to ${BASTION_USER}@${BASTION_IP}'s authorized_keys."
