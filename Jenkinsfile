#!/usr/bin/env groovy
pipeline {
    agent {
      node {
        label 'fedora31'
      }
    }

    environment {
        TEST_CONTAINER = "${env.TEST_PREFIX}-${env.BUILD_NUMBER}"
    }

    stages {
        stage("Basic test") {
            steps {
              ansiColor('xterm') {
                sh "uname -a"
                sh "dnf -y install python3-ansible-lint"
                sh "ansible-lint --force-color playbook.yml"
              }
            }
        }
    }
}
