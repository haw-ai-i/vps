#!/bin/bash
# setup-client.sh - Helps configure a client laptop for the bastion setup

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <laptop_id>"
    echo "Example: $0 laptop-a"
    exit 1
fi

LAPTOP_ID=$1
KEY_FILE="${HOME}/.ssh/id_ed25519_bastion_${LAPTOP_ID}"

echo "Generating unique keypair for ${LAPTOP_ID}..."
if [ -f "${KEY_FILE}" ]; then
    echo "Key ${KEY_FILE} already exists. Skipping generation."
else
    ssh-keygen -t ed25519 -f "${KEY_FILE}" -C "${LAPTOP_ID} bastion" -N ""
fi

echo ""
echo "Step 1: Copy this public key string:"
cat "${KEY_FILE}.pub"
echo ""
echo "Step 2: Authorize it on the Bastion from your Primary Laptop:"
echo "export NEW_KEY=\"\$(cat ${KEY_FILE}.pub)\""
echo "ssh <bastion_user>@<bastion_ip> \"echo '\$NEW_KEY' >> ~/.ssh/authorized_keys\""
echo ""
echo "Step 3: Add these entries to your ~/.ssh/config:"
echo ""
cat <<EOF
Host bastion
    HostName <BASTION_IP>
    User <BASTION_USER>
    IdentityFile ${KEY_FILE}
    IdentitiesOnly yes

# Example for host-a
Host host-a
    HostName localhost
    Port 2202
    User <internal_username>
    ProxyJump bastion
EOF
