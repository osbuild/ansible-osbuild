#!/bin/bash
set -euxo pipefail

# Get the current journald cursor.
export JOURNALD_CURSOR=$(sudo journalctl --quiet -n 1 --show-cursor | tail -n 1 | grep -oP 's\=.*$')

# Add a function to preserve the system journal if something goes wrong.
preserve_journal() {
  # sleep 3600
  sudo journalctl --after-cursor=${JOURNALD_CURSOR} > systemd-journald.log
  exit 1
}
trap "preserve_journal" ERR

# Get OS details.
source /etc/os-release

# Get the latest master artifacts from osbuild-composer.
REPO_BASE_URL=https://rhos-d.infra.prod.upshift.rdu2.redhat.com:13808/v1/AUTH_95e858620fb34bcc9162d9f52367a560/osbuildci-artifacts
# CI_ARTIFACTS=$(curl -sk ${REPO_BASE_URL}/ | egrep -o "jenkins-osbuild-osbuild-composer-master-[0-9]+" | tail -n 1)
CI_ARTIFACTS=osbuild/osbuild-composer/master/347d69b

# Set up a dnf repository for a previously built known working package of
# osbuild and osbuild-composer.
sudo tee /etc/yum.repos.d/osbuild-mock.repo > /dev/null << EOF
[osbuild-mock]
name=osbuild mock
baseurl=${REPO_BASE_URL}/${CI_ARTIFACTS}/${ID}${VERSION_ID//./}
enabled=1
gpgcheck=0
# Default dnf repo priority is 99. Lower number means higher priority.
priority=5
EOF

# Verify that the repository we added is working properly.
sudo dnf repository-packages osbuild-mock list

# Create temporary directories for Ansible.
sudo mkdir -vp /opt/ansible_{local,remote}
sudo chmod -R 777 /opt/ansible_{local,remote}

# This should eventually be added to the image itself.
sudo dnf -y install python3-botocore python3-boto python3-boto3
sudo pip3 install awscli || sudo pip install awscli

# Run deployment.
echo -e "[test_instances]\nlocalhost ansible_connection=local" > hosts.ini
ansible-playbook -i hosts.ini ${EXTRA_VARS:-} playbook.yml

# Once everything is deployed, add a blueprint and build it just to ensure
# everything is working.
ansible-playbook -v -i hosts.ini schutzbot/composer-smoke-test.yml

# Preserve the system journal.
sudo journalctl --after-cursor=${JOURNALD_CURSOR} > systemd-journald.log