# Scalable VPS Reverse SSH Tunnel System

This project provides a robust framework for securely accessing internal hosts behind NAT via a central Bastion VPS.

## Key Features
- **Unique Laptop Identities**: Each client uses its own SSH key.
- **Per-Host Usernames**: Configurable usernames for each internal host.
- **Secure by Default**: Reverse tunnels are bound to `127.0.0.1` on the bastion.
- **Persistence**: Automated via `autossh` and `systemd`.

### 0. Preparation (Local Laptop)
Before starting, ensure you have an SSH keypair on your local machine. If you don't have one, generate it:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```
The public key will typically be saved at `~/.ssh/id_ed25519.pub`. This path is what you will use for the `ssh_public_key_path` variable.

### 1. Bastion Provisioning

### Terraform
1. Navigate to `terraform/`.
2. Copy `terraform.tfvars.example` to `terraform.tfvars`.
3. Fill in your `project_id`.
4. Set `bastion_ssh_user` to your desired username (e.g., your local username).
5. Ensure `ssh_public_key_path` points to your public key (e.g., `~/.ssh/id_ed25519.pub`).
6. Ensure you have the `gcloud` CLI installed and authenticated (`gcloud auth application-default login`).
4. Run:
   ```bash
   terraform init
   terraform apply
   ```
5. Note the output `bastion_ip`.

### Hardening the Bastion
Once the VPS is up, you need to transfer the `setup-bastion.sh` script to the server and run it.

1. **Transfer the script**:
   From your local terminal (inside the `vps` project directory), run:
   ```bash
   scp scripts/setup-bastion.sh bastionadmin@136.114.249.178:~/
   ```

2. **SSH into the Bastion**:
   ```bash
   ssh bastionadmin@136.114.249.178
   ```

3. **Run the hardening script**:
   On the bastion host:
   ```bash
   sudo bash ~/setup-bastion.sh
   ```

## 2. Internal Host Setup

For each host behind NAT you want to reach (e.g., `host-a`):

1. **Authorize this host to the Bastion**:
   From the internal host, send its public key to the bastion:
   ```bash
   ssh-copy-id bastionadmin@136.114.249.178
   ```

2. **Transfer the setup script**:
   From your local project directory:
   ```bash
   scp scripts/setup-internal-host.sh internal-user@internal-host-ip:~/
   ```

3. **Run the setup script on the internal host**:
   ```bash
   # Usage: ./setup-internal-host.sh <host_name> <bastion_ip> <bastion_user> <reverse_port>
   bash ~/setup-internal-host.sh host-a 136.114.249.178 bastionadmin 2201
   ```

4. **Verify the tunnel**:
   ```bash
   sudo systemctl status reverse-ssh-host-a
   ```

## 3. Client (Laptop) Registration

On each laptop you want to use for connecting:

1. **Run client setup**:
   ```bash
   ./scripts/setup-client.sh laptop-a
   ```
   This generates a unique key: `~/.ssh/id_ed25519_bastion_laptop-a`.

2. **Authorize the laptop to the Bastion**:
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519_bastion_laptop-a bastionadmin@136.114.249.178
   ```

3. **Update your Local SSH Config**:
   Add these entries to your `~/.ssh/config`:
   ```text
   Host bastion
       HostName 136.114.249.178
       User bastionadmin
       IdentityFile ~/.ssh/id_ed25519_bastion_laptop-a
       IdentitiesOnly yes

   Host host-a
       HostName localhost
       Port 2201
       User <internal_username_on_host_a>
       ProxyJump bastion
   ```

## 4. Usage

Now you can reach your internal host directly:
```bash
ssh host-a
```

## 5. Revoking Access
To revoke a laptop's access, simply remove its unique public key from the Bastion's `/home/<bastionuser>/.ssh/authorized_keys` file.
