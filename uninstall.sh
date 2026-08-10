#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "Error: Please specify the target hostname to uninstall (e.g., ./uninstall.sh aap-control4.phatsplace.org)"
    exit 1
fi

TARGET_HOST=$1
INV_FILE="inventory-growth.${TARGET_HOST}"
PASS_FILE=".become_pass.${TARGET_HOST}"

echo "========================================================="
echo " Building Inventory and Removing: $TARGET_HOST"
echo "========================================================="

trap 'rm -f "$INV_FILE" "$PASS_FILE"' EXIT

sed "s/__TARGET_HOST__/${TARGET_HOST}/g" inventory-growth.template > "$INV_FILE"

echo "GGB!pa22wdGGB!pa22wd" > "$PASS_FILE"
chmod 600 "$PASS_FILE"

#stop over auditing for install and uninstall
ansible-playbook -i "$INV_FILE" auditd_pre_install.yml \
  --become-password-file "$PASS_FILE"

#uninstall
ansible-playbook -i "$INV_FILE" ansible.containerized_installer.uninstall \
  --become-password-file "$PASS_FILE"

#put back the over auditing
ansible-playbook -i "$INV_FILE" auditd_post_install.yml \
  --become-password-file "$PASS_FILE"


echo "Removal complete for $TARGET_HOST."

