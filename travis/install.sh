#!/bin/bash

# Install Ansible
pip -q install ansible

# Set up ssh keys and ssh daemon.
ssh-keygen -b 4096 -t rsa -f /tmp/sshkey -q -N ""
mkdir -vp ~/.ssh && chmod 0700 ~/.ssh
cat /tmp/sshkey.pub >> ~/.ssh/authorized_keys && chmod 0700 ~/.ssh/authorized_keys
sudo systemctl start ssh