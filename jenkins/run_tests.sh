#!/bin/bash
set -euxo pipefail

exit 1

# Set an output path for the junit file.
export JUNIT_OUTPUT_DIR=junit/

# Ensure we have the right packages installed.
sudo dnf -y install ansible python3-junit_xml

# Check to see if we are supposed to run integration tests.
if [[ ${RUN_INTEGRATION_TESTS:-0} == 1 ]]; then
  EXTRA_VARS="-e 'run_integration_tests=yes'"
fi

# Run a deployment
echo -e "[test_instances]\nlocalhost ansible_connection=local" > hosts.ini
ansible-playbook -i hosts.ini ${EXTRA_VARS:-} playbook.yml

# Get the integration test logs if they exist and we are running under Jenkins.
if [ -e "/tmp/composer_tests.log.xz" ] && [ -n "${WORKSPACE:-}"] ; then
  cp /tmp/composer_tests.log.xz $WORKSPACE
fi
