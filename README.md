# AWS Windows Domain Controller Provisioning

This project automates the provisioning and configuration of a Windows Server 2022 Active Directory Domain Controller (DC) on AWS using Terraform and PowerShell. It includes a fully automated post-installation configuration cycle and continuous integration/continuous deployment (CI/CD) workflows.

## Architecture

- **AWS Infrastructure (Terraform)**:
  - **VPC**: Dedicated Virtual Private Cloud with a public subnet, internet gateway, and route tables for ingress/egress routing.
  - **EC2 Instance**: Windows Server 2022 (`t3.large`) provisioned inside the public subnet.
  - **S3 Bucket**: Secure storage resource provisioned with versioning, bucket lifecycle policies, and server-side encryption (SSE-KMS) with customer managed keys.
  - **Security Group**: Restricts RDP (port 3389) dynamically to the deployment host's public IP address (retrieved in real-time via `api.ipify.org`).

- **OS Configuration (PowerShell)**:
  - Automated Active Directory Domain Services (AD DS) installation and forest promotion.
  - Organization Unit (OU) and test user provisioning.
  - Group Policy Objects (GPOs) enforcement.
  - Scheduled task implementation.

---

## Key Design Decisions

- **Two-Phase Agentless Provisioning**: Used native PowerShell combined with the Windows `RunOnce` registry key. This eliminates the need for external configuration management tooling (e.g., Ansible, Chef) while successfully navigating the mandatory system reboot required during Active Directory promotion.
- **Dynamic IP Restriction**: Rather than exposing RDP (port 3389) to `0.0.0.0/0`, the configuration dynamically fetches the deployment operator's public IP via `api.ipify.org` during execution, restricting ingress traffic specifically to the authorized administrator.
- **Automated Policy and Security Scanning**: Included Checkov (SAST) and Open Policy Agent (OPA) directly in the CI/CD pull request lifecycle. This ensures compliance checks and security scans are executed prior to resource modification.
- **Secure Password Lifecycle**: Used Terraform's `random_password` provider to generate the Administrator password programmatically, outputting it securely via outputs rather than hardcoding credentials in configuration scripts.

---

## CI/CD Workflows (GitHub Actions)

The repository provides automated pipelines under `.github/workflows/` to manage code quality, security, and deployment:

### 1. Terraform Validate (`terraform-validate.yaml`)
- **Trigger**: Automatic on `push` and `pull_request` to the `main` branch.
- **Jobs**:
  - **Validate**: Formats (`terraform fmt -check`), initializes without backend (`terraform init -backend=false`), and runs static validation (`terraform validate`).
  - **Security Scan**: Utilizes **Checkov** to run static application security testing (SAST) on Terraform configurations.
  - **OPA Policy Check**: Executes Open Policy Agent (OPA) checks to ensure compliance with organization infrastructure policies.

### 2. Terraform Apply (`terraform-apply.yaml`)
- **Trigger**: Manual (`workflow_dispatch`).
- **Jobs**:
  - **Plan**: Generates and uploads the execution plan (`tfplan`) as an artifact.
  - **Apply**: Downloads the artifact and applies changes. Employs GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) for AWS authentication.
  - **Summary**: Writes the deployment output parameters directly to the GitHub Action workflow summary.

### 3. Terraform Destroy (`terraform-destroy.yaml`)
- **Trigger**: Manual (`workflow_dispatch`).
- **Jobs**:
  - **Destroy**: Tear down all resources provisioned by the workspace to prevent active charges.

---

## How the Automation Cycle Works

The OS configuration runs completely unattended by leveraging EC2 UserData and Windows `RunOnce` registry settings:

1. **Phase 1: Boot & AD DS Installation**:
   - The instance boots and retrieves the `configure-ad.ps1` script from the S3 bucket.
   - UserData triggers the initial run of the script.
   - The script installs the AD DS role and promotes the server to a Domain Controller for the `lab.local` domain.
   - The promotion process triggers a mandatory system reboot.
   - Before rebooting, a registry key is added to `HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce` to resume script execution.

2. **Phase 2: Post-Reboot Configuration**:
   - Upon reboot, the system automatically logs in as Administrator and resumes execution via `RunOnce`.
   - The script detects that the AD DS role is active and proceeds with:
     - Creating the target OU (`OU=TestOU,DC=lab,DC=local`).
     - Provisioning `testuser@lab.local` with standard user and remote access privileges.
     - Creating and linking GPOs (Notepad auto-launch and C:\ drive restriction).
     - Scheduling a daily reboot task at 03:00 AM.
     - Finalizing system security and removing the `RunOnce` registry key.

---

## Deployment Instructions

### Option A: Local Deployment

1. **Initialize Backend and Providers**:
   ```bash
   cd environments/dev
   terraform init
   ```
2. **Apply Configurations**:
   ```bash
   terraform apply -auto-approve
   ```

### Option B: CI/CD Deployment

1. Configure AWS credentials as GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`).
2. Run the **Terraform Apply** workflow manually in the GitHub Actions tab.
3. Access the output details in the GitHub Run Summary.

---

## Credentials & RDP Access

After running `terraform apply`, retrieve the deployment credentials and connection parameters directly from the Terraform outputs:

### 1. Host IP & Connection Command
- **Server Public IP**: Retrieve via `terraform output -raw windows_public_ip`
- **RDP Direct Command**: Retrieve via `terraform output -raw rdp_command` (e.g., `mstsc /v:<ip>`)

### 2. Administrator Account (Local Admin)
- **Username**: Retrieve via `terraform output -raw username` (returns `.\Administrator`)
- **Password**: Retrieve via `terraform output -raw admin_password`

### 3. Test Domain Account (Standard Domain User)
- **Username**: `testuser@lab.local` (or `LAB\testuser`)
- **Password**: `P@ssw0rd123!`
- **Access Privilege**: Standard domain user, member of `Domain Users` and `Remote Desktop Users` (use this account to test GPO limitations).

---

## Project Structure

```
├── environments/
│   ├── bootstrap/          # Terraform state backend infrastructure
│   └── dev/                # Development environment workspace
│       ├── main.tf         # Main declaration of modules and variables
│       ├── provider.tf     # AWS Provider and S3 Backend configuration
│       └── outputs.tf      # Standard outputs (IP, credentials, commands)
├── modules/
│   ├── s3/                 # Provisioning of the setup script storage bucket
│   ├── security-group/     # Ingress rules with dynamic IP fetching
│   ├── vpc/                # Virtual Private Cloud networking module
│   └── windows-server/     # Windows EC2 instance and UserData boot cycle
├── policies/
│   └── terraform.rego      # Rego files for Open Policy Agent (OPA) validation
└── scripts/
    ├── configure-ad.ps1    # Automated AD DS promotion & post-reboot configuration
    └── setup.sh            # Local helper bootstrap script
```

---

## Deliverables & Configurations

### Domain Settings
- **Forest Domain**: `lab.local`
- **Functional Level**: Windows Server 2016

### Group Policy Objects (GPOs)
- **Launch Notepad on Logon**: Automatically runs `notepad.exe` for all users on login.
- **Restrict C Drive Access**: Restricts standard domain users (non-admins) from accessing `C:\` via Explorer.

### Task Scheduler
- **Name**: `DailyReboot`
- **Schedule**: Every day at 03:00 AM.
- **Action**: `shutdown.exe /r /t 0 /f`

### Active Directory Assets
- **OU**: `OU=TestOU,DC=lab,DC=local`
- **Standard User**: `testuser@lab.local` (Password: `P@ssw0rd123!`, member of Domain Users and Remote Desktop Users).

---

## Post-Deployment Verification

Log into the Domain Controller using RDP (using the parameters retrieved in the **Credentials & RDP Access** section) and execute the following PowerShell commands to verify the setup:

```powershell
# Verify Domain status
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode

# Verify Active GPOs
gpresult /r

# Verify Scheduled Task
Get-ScheduledTask -TaskName DailyReboot | Select-Object TaskName, State, Actions

# Verify Test User setup
Get-ADUser -Filter "SamAccountName -eq 'testuser'"
```

---

## Production Recommendations

For staging or production deployments, address the following security and architecture details:
- **Network Isolation**: Deploy the EC2 instance in a private subnet and configure AWS Systems Manager (SSM) for management instead of exposing RDP port 3389.
- **State Management**: Use remote state storage with state locking (e.g., S3 backend with DynamoDB locking).
- **Resource Lifecycle**: Implement `prevent_destroy = true` lifecycle blocks on critical assets.
- **Logging & Monitoring**: Enable AWS CloudTrail, VPC Flow Logs, and ship Windows Event logs to a centralized log management tool.
