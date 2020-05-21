#!/bin/bash
set -euxo pipefail

hold_node() {
  ip addr
  sleep 3600
  exit 1
}
trap "hold_node" ERR

# Get OS details.
source /etc/os-release

# Set up a dnf repository for a previously built known working package of
# osbuild and osbuild-composer.
REPO_BASE_URL=https://rhos-d.infra.prod.upshift.rdu2.redhat.com:13808/v1/AUTH_95e858620fb34bcc9162d9f52367a560/osbuildci-artifacts
sudo tee /etc/yum.repos.d/osbuild-mock.repo > /dev/null << EOF
[osbuild-mock]
name=osbuild mock
baseurl=${REPO_BASE_URL}/jenkins-osbuild-osbuild-composer-PR-657-1/${ID}${VERSION_ID//./}
enabled=1
gpgcheck=0
# Default dnf repo priority is 99. Lower number means higher priority.
priority=5
EOF

# Verify that the repository we added is working properly.
dnf list all | grep osbuild-mock

# Create temporary directories for Ansible.
sudo mkdir -vp /opt/ansible_{local,remote}
sudo chmod -R 777 /opt/ansible_{local,remote}

# Run deployment.
echo -e "[test_instances]\nlocalhost ansible_connection=local" > hosts.ini
ansible-playbook -i hosts.ini ${EXTRA_VARS:-} playbook.yml

# Mount a ramdisk on /run/osbuild to speed up testing.
sudo mkdir -p /run/osbuild
sudo mount -t tmpfs tmpfs /run/osbuild

# Replace the RHEL 8.3 repository file.
sudo cp schutzbot/rhel-8.3.json \
    /usr/share/osbuild-composer/repositories/rhel-8.3.json

# Once everything is deployed, add a blueprint and build it just to ensure
# everything is working.
ansible-playbook -i hosts.ini schutzbot/composer-smoke-test.yml