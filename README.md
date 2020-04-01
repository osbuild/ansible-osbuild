# ansible-osbuild TEST

This repository contains a set of Ansible playbooks and roles for deploying
osbuild and osbuild-composer on Fedora 31+, RHEL 8.2+, and CentOS 8.2+.

## Deploying personal test infrastructure

You can use the scripts and playbooks here to deploy your own testing
infrastructure on EC2.

### Prepare your AWS CLI

Start by [installing the AWS CLI version 2]:

```text
dnf install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

After the installation, run the [configuration step]:

```text
aws configure --profile personal
```

Verify that you can authenticate with AWS:

```text
aws s3 ls
aws sts get-caller-identity
```

### Install Ansible

Install some packages for Ansible and its support for EC2:

```text
dnf install ansible python3-boto3
```

### Configure EC2 variables

EC2 variables are stored in [`ec2/ec2_vars.yml`] and they control how the EC2 infrastructure is provisioned. The most important ones to review are:

* `aws_region`: The `us-east-2` region is chosen by default, but you may
  prefer a region that is geographically closer to you. Keep in mind that some
  regions are *much more expensive* than others.

* `aws_profile`: This should match with the AWS CLI profile that you set up in
  the first step. It provides a hint to Ansible and the AWS CLI about where
  they should look to find credentials for EC2 APIs.

* `instance_types`: *Review the EC2 [on-demand pricing] as well as the [spot
  instance pricing] before making changes.* You can update the list of
  instance types for each architecture depending on your needs. The most
  preferred instance types should be at the top of the list.

* `use_spot_instances`: Spot instances save money by using excess capacity in
  EC2 for a much lower price. However, AWS can terminate the instance at any
  time, no instance can last longer than 24 hours, and there are some
  situations where no spot instance capacity is available in certain
  availability zones. The playbooks will retry spot instance requests when
  capacity is not available, but there's still a change that your request will
  not be fulfilled. Set this variable to `no` if you want to use on-demand
  instances and be guaranteed an instance (at a much higher price).

* `instances_to_deploy`: This dictionary controls which instances will be
  deployed. If you want to disable any of the deployments, adjust the
  `enabled` key to `no` for each instance that you do not want to provision.

[`ec2/ec2_vars.yml`]: blob/master/ec2/ec2_vars.yml
[on-demand pricing]: https://aws.amazon.com/ec2/pricing/on-demand/
[spot instance pricing]: https://aws.amazon.com/ec2/spot/pricing/

### Configure the deployment variables

You will find deployment variables inside [`vars.yml`].

First, ensure your ssh key is included in `valid_ssh_keys`. These ssh keys
will be deployed to the instances to allow password-less ssh connectivity.

By default, the code from the master branches of the main repos is deployed.
You can adjust this by uncommenting the variables in the variables files and
providing your own repository URL, refspec, or version (SHA or tag).

[`vars.yml`]: blob/master/vars.yml

### Run the deployment

Run the script:

```text
./deploy_ec2.sh
```

There are two phases of the deployment:

1. Creating infrastructure on EC2 to run the osbuild/osbuild-composer services
2. Deploying the osbuild/osbuild-composer services

The first step should take 2-3 minutes. The second step takes a little longer
since all of the RPMs must be built and deployed.

When it's all finished, your deployed instances should be in
``/tmp/osbuild.personal.USERNAME/hosts.ini`` Use the IP address, username, and
private key file shown there to log in.

[installing the AWS CLI version 2]: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
[configuration step]: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html
