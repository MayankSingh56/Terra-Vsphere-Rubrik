# Terraform VM + PostgreSQL Deployment (Enterprise Ready)

# Python automation script added in main machine to automate the terraform process.

Automates deployment of a VM on vSphere and installs PostgreSQL.

## Features
- OS: RHEL9, Debian12, Oracle Linux 9, SLES15
- PostgreSQL: Community, EDB AS, EDB PGE
- NFS client setup

## Usage
```sh
terraform init
terraform plan
terraform apply
```

Check:
```sh
psql --version
systemctl status postgresql-17
systemctl status nfs-utils.service
```
