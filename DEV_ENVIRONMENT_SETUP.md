# Enterprise Development Environment Setup Guide
## Terraform VM + PostgreSQL Deployment

### Table of Contents
1. [Prerequisites](#prerequisites)
2. [Development Environment Setup](#development-environment-setup)
3. [Infrastructure Requirements](#infrastructure-requirements)
4. [Security Configuration](#security-configuration)
5. [Development Workflow](#development-workflow)
6. [Testing & Validation](#testing--validation)
7. [CI/CD Integration](#cicd-integration)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements
- **OS**: Windows 10/11, macOS 10.15+, or Linux (Ubuntu 20.04+)
- **RAM**: Minimum 8GB, Recommended 16GB
- **Storage**: 50GB free space
- **Network**: Corporate VPN access to vSphere infrastructure

### Required Software Stack
```bash
# Core Tools
terraform >= 1.6.0
git >= 2.30.0
ssh-client
curl/wget

# Development Tools
vscode (recommended) or vim/nano
terraform-ls (language server)
tflint >= 0.44.0
checkov >= 2.0.0

# Optional but Recommended
pre-commit >= 2.20.0
terraform-docs >= 0.16.0
```

---

## Development Environment Setup

### 1. Tool Installation

#### Windows (PowerShell as Administrator)
```powershell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools
choco install terraform git vscode openssh
```

#### macOS
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install terraform git tflint checkov pre-commit terraform-docs
```

#### Linux (Ubuntu/Debian)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install additional tools
sudo apt install git curl wget openssh-client
```

### 2. IDE Configuration

#### VS Code Extensions
```json
{
  "recommendations": [
    "hashicorp.terraform",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-vscode-remote.remote-ssh",
    "bridgecrew.checkov"
  ]
}
```

#### VS Code Settings
```json
{
  "terraform.experimentalFeatures.validateOnSave": true,
  "terraform.experimentalFeatures.prefillRequiredFields": true,
  "files.associations": {
    "*.tfvars": "terraform"
  }
}
```

---

## Infrastructure Requirements

### vSphere Environment
- **vCenter Server**: 7.0+ with API access
- **ESXi Hosts**: 7.0+ with sufficient resources
- **Network**: VLAN with DHCP/Static IP capability
- **Storage**: Shared datastore with 100GB+ free space

### VM Templates Required
```hcl
# Supported OS Templates
rhel9-template     # RHEL 9.x with cloud-init
debian12-template  # Debian 12 with cloud-init
oracle9-template   # Oracle Linux 9.x
sles15-template    # SUSE Linux Enterprise 15
```

### Network Configuration
- **Management Network**: Corporate network access
- **VM Network**: Isolated or DMZ network for database VMs
- **Firewall Rules**: PostgreSQL port 5432, SSH port 22

---

## Security Configuration

### 1. Credential Management

#### Environment Variables (Recommended)
```bash
# Create .env file (never commit to git)
export TF_VAR_vsphere_user="service-account@vsphere.local"
export TF_VAR_vsphere_password="SecurePassword123!"
export TF_VAR_vsphere_server="vcenter.company.com"

# Source the file
source .env
```

#### HashiCorp Vault Integration
```hcl
# vault.tf
data "vault_generic_secret" "vsphere" {
  path = "secret/vsphere"
}

locals {
  vsphere_user     = data.vault_generic_secret.vsphere.data["username"]
  vsphere_password = data.vault_generic_secret.vsphere.data["password"]
}
'''

---

## Development Workflow

### 1. Project Setup
```bash
# Clone repository
git clone <repository-url>
cd terraform repo-name

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
terraform fmt -check
```



### 3. Configuration Management

#### Environment-specific tfvars
```bash
# environments/dev.tfvars
vm_name = "pg-dev01"
vm_cpu  = 2
vm_memory = 4096
guest_os_type = "rhel9"

# environments/staging.tfvars
vm_name = "pg-stg01"
vm_cpu  = 4
vm_memory = 8192

# environments/prod.tfvars
vm_name = "pg-prd01"
vm_cpu  = 8
vm_memory = 16384
```

### 4. Deployment Process
```bash
# Plan deployment
terraform plan -var-file="environments/dev.tfvars" -out=tfplan

# Review plan
terraform show tfplan

# Apply changes
terraform apply tfplan

# Verify deployment
terraform output vm_ip
```

---

## Testing & Validation

### 1. Infrastructure Testing
```bash
# Validate Terraform syntax
terraform validate

# Security scanning
checkov -f main.tf

# Linting
tflint --init
tflint
```



---

## CI/CD Integration

### 1. GitHub Actions Workflow
```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Validate
        run: terraform validate
      
      - name: Terraform Plan
        run: terraform plan -var-file="environments/dev.tfvars"
        env:
          TF_VAR_vsphere_user: ${{ secrets.VSPHERE_USER }}
          TF_VAR_vsphere_password: ${{ secrets.VSPHERE_PASSWORD }}
```

### 2. GitLab CI Pipeline
```yaml
# .gitlab-ci.yml
stages:
  - validate
  - plan
  - apply

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_IN_AUTOMATION: "true"

validate:
  stage: validate
  script:
    - terraform init
    - terraform validate
    - terraform fmt -check

plan:
  stage: plan
  script:
    - terraform plan -var-file="environments/dev.tfvars"
  artifacts:
    paths:
      - tfplan
```

---

## Troubleshooting

### Common Issues

#### 1. vSphere Connection Issues
```bash
# Test vCenter connectivity
curl -k https://$VSPHERE_SERVER/ui/

# Verify credentials
govc about -u "$VSPHERE_USER:$VSPHERE_PASSWORD@$VSPHERE_SERVER"
```

#### 2. VM Template Issues
```bash
# List available templates
govc vm.info -u "$VSPHERE_USER:$VSPHERE_PASSWORD@$VSPHERE_SERVER" "*/vm/*template*"

# Check template configuration
terraform console
> data.vsphere_virtual_machine.template
```

#### 3. SSH Connection Failures
```bash
# Check VM network configuration
ssh -v cloud-user@$VM_IP


```

#### 4. PostgreSQL Installation Issues
```bash
# Check bootstrap script logs
ssh cloud-user@$VM_IP "sudo journalctl -u cloud-final"

# Manual PostgreSQL verification
ssh cloud-user@$VM_IP "sudo systemctl status postgresql-17"
ssh cloud-user@$VM_IP "sudo -u postgres psql -c 'SELECT version();'"
```

### Debug Mode
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run with verbose output
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

### Recovery Procedures
```bash
# Force unlock state
terraform force-unlock <LOCK_ID>

# Import existing resources
terraform import vsphere_virtual_machine.vm <VM_MOID>

# Destroy and recreate
terraform destroy -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

---

## Best Practices

### 1. Code Organization
- Use modules for reusable components
- Separate environments with tfvars files
- Implement proper variable validation
- Use consistent naming conventions

### 2. State Management
- Use remote state backend (S3, Azure Storage, etc.)
- Enable state locking
- Regular state backups
- Never commit state files to git

### 3. Security
- Use service accounts for automation
- Implement least privilege access
- Encrypt sensitive variables
- Regular credential rotation

### 4. Documentation
- Keep README.md updated
- Document all variables
- Maintain changelog
- Include architecture diagrams

---

*Last Updated: $(10-16-2025)*
*Version: 1.0*