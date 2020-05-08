#!/bin/bash
set -euxo pipefail

# Set up the VM inside travis.
ansible-playbook \
    -i localhost, \
    -e testing_os=${TESTING_OS} \
    -e testing_os_version=${TESTING_OS_VERSION} \
    travis/playbook.yml

# Deploy to the VM.
ansible-playbook -i /tmp/hosts.ini playbook.yml