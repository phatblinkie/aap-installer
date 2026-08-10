#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "Error: Please specify the target hostname (e.g., ./install.sh aap-control4.phatsplace.org)"
    exit 1
fi

TARGET_HOST=$1

# Unique runtime file definitions to ensure complete isolation
INV_FILE="inventory-growth.${TARGET_HOST}"
PASS_FILE=".become_pass.${TARGET_HOST}"
# Define the dynamic environment variable string to inject into the playbooks
# This forces Podman to use your home folder for rootless image extraction
EXTRA_ENV_VARS="{'TMPDIR': '~/.ansible/tmp'}"

echo "========================================================="
echo " Building Inventory and Provisioning: $TARGET_HOST"
echo "========================================================="

# Automatically clean up temp files on script exit, failure, or interruption
trap 'rm -f "$INV_FILE" "$PASS_FILE"' EXIT

# Render the active isolated inventory file from the template
sed "s/__TARGET_HOST__/${TARGET_HOST}/g" inventory-growth.template > "$INV_FILE"

# Create the host-isolated password file
echo "GGB!pa22wdGGB!pa22wd" > "$PASS_FILE"
chmod 600 "$PASS_FILE"

echo "=== STEP 1: Running Pre-Install Auditd Optimization ==="
ansible-playbook -i "$INV_FILE" auditd_pre_install.yml \
  --become-password-file "$PASS_FILE"

#echo "=== STEP 1b: Running Pre-Pull Staging for Container Images ==="
## No become-password needed here because the playbook runs explicitly as the rootless 'aap' user
#ansible-playbook -i "$INV_FILE" container_pre_pull.yml

echo "=== STEP 2: Running AAP 2.5 Containerized Installer ==="
ansible-playbook -i "$INV_FILE" ansible.containerized_installer.install \
  --become-password-file "$PASS_FILE" -v

echo "=== STEP 3: Running Post-Install Auditd Rollback ==="
ansible-playbook -i "$INV_FILE" auditd_post_install.yml \
  --become-password-file "$PASS_FILE"

echo "========================================================="
echo " System Installation and Security Rollback Complete!    "
echo "========================================================="

