#!/bin/bash
set -euxo pipefail

# Create temporary directories for Ansible.
sudo mkdir -vp /opt/ansible_{local,remote}
sudo chmod -R 777 /opt/ansible_{local,remote}

# Set up a basic hosts file.
echo -e "[test_instances]\nlocalhost ansible_connection=local" > hosts.ini

# Build the RPMs in a mock chroot.
ansible-playbook -i localhost, -e ansible_connection=local tools/mock_build.yml

# Deploy osbuild and osbuild-composer
ansible-playbook -i hosts.ini ${EXTRA_VARS:-} playbook.yml

# Mount a ramdisk on /run/osbuild to speed up testing.
sudo mkdir -p /run/osbuild
sudo mount -t tmpfs tmpfs /run/osbuild

# Once everything is deployed, add a blueprint and build it just to ensure
# everything is working.
ansible-playbook -i hosts.ini schutzbot/composer-smoke-test.yml