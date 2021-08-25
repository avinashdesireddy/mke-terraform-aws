# Bootstrapping MKE cluster on AWS

This directory provides an example flow for using Mirantis Launchpad with Terraform and AWS.

## Prerequisites

* An account and credentials for AWS.
* Terraform [installed](https://learn.hashicorp.com/terraform/getting-started/install)

## Steps
1. Create/Use terraform workspace
   ```
   terraform workspace list
   ```
2. Export AWS credentials
3. Create terraform.tfvars file with needed details. You can use the provided terraform.tfvars.example as a baseline.
4. Run terraform 
   ```
   terraform init
   terraform apply -var-file="terraform.tfvars"
   ```

5. Create a launchpad file from terraform output
   ```
   terraform output mke_cluster > launchpad.yaml
   ```

6. Create a cluster using launchpad config
   ```
   launchpad apply -c launchpad.yaml
   ```
