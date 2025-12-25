#!/bin/bash
# setup-bastion.sh - Hardens the bastion SSH configuration

set -e

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Hardening SSH configuration..."

# Backup existing config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Update configurations
# - Disable password authentication
# - Disable root login
# - Enable pubkey authentication
# - Allow TCP forwarding
# - GatewayPorts no (critical for security - prevents public exposure of tunnels)
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
sed -i 's/^#\?GatewayPorts.*/GatewayPorts no/' /etc/ssh/sshd_config

# Check syntax
sshd -t

# Restart SSH service
systemctl restart ssh

echo "SSH hardening complete."
echo "Note: If you are connected via SSH, your session should remain active, but new connections will require public keys."
