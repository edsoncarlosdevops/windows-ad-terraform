# Windows AD Domain Controller with Terraform

This project automates the provisioning of a **Windows Server 2022 EC2 instance** and configures it as an **Active Directory Domain Controller** using Terraform and PowerShell.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  AWS Cloud                          │
│                                                      │
│  ┌──────────────┐    ┌──────────────┐               │
│  │   S3 Bucket  │    │  Security    │               │
│  │  (Scripts)   │    │   Group      │               │
│  └──────────────┘    └──────┬───────┘               │
│                             │                       │
│                    ┌────────▼────────┐              │
│                    │  Windows Server │              │
│                    │  2022 EC2       │              │
│                    │  lab.local      │              │
│                    │  Domain Ctrl    │              │
│                    └─────────────────┘              │
└─────────────────────────────────────────────────────┘
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- An AWS account with permissions to create EC2, S3, and Security Groups

## Quick Start

```bash
# Clone the repository
git clone <your-repo-url>
cd windows-ad-terraform/environments/dev

# Initialize Terraform
terraform init

# Deploy everything
terraform apply -auto-approve
```

**⏱ Wait ~15 minutes** for the server to fully configure (AD installation, promotion, reboot, and post-reboot setup).

## Accessing the Server

### Administrator Access

| Field | Value |
|-------|-------|
| **Username** | `.\Administrator` |
| **Password** | `Admin@12345` |

### Test User Access

| Field | Value |
|-------|-------|
| **Username** | `testuser@lab.local` |
| **Password** | `P@ssw0rd123!` |

> **Note:** `testuser` is a regular domain user (non-admin). Use it to validate GPO restrictions.

### Get server IP

```bash
terraform output
```

## What Gets Configured Automatically

### ✅ Active Directory
- **Domain**: `lab.local` (NetBIOS: `LAB`)
- **Forest/Domain functional level**: Windows 2016
- **DNS** installed and integrated with AD

### ✅ Group Policies (GPOs)

| GPO Name | Description | Scope |
|----------|-------------|-------|
| **Launch Notepad on Logon** | Automatically opens Notepad when any domain user logs in | All domain users |
| **Restrict C Drive Access** | Prevents non-admin users from browsing the C:\ drive | All domain users |

### ✅ Organizational Unit & Test User

- **OU**: `OU=TestOU,DC=lab,DC=local`
- **Test User**: `testuser@lab.local` / `P@ssw0rd123!`
  - Member of: `Domain Users`, `Remote Desktop Users`
  - Password never expires

### ✅ Scheduled Task

| Task Name | Trigger | Action |
|-----------|---------|--------|
| **DailyReboot** | Daily at 03:00 AM | Reboots the server |

### ✅ Security Configuration

- **RDP access**: Restricted to the IP of whoever runs `terraform apply` (dynamic IP detection)
- **WinRM**: Basic auth enabled
- **Firewall**: Disabled for testing purposes

## Validation Checklist

After deployment, run these commands inside the server to validate everything:

```powershell
# 1. Check domain status
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode

# 2. Check applied GPOs
gpresult /r

# 3. Check test user
Get-ADUser -Filter "SamAccountName -eq 'testuser'"

# 4. Check scheduled task
Get-ScheduledTask -TaskName DailyReboot | Select-Object TaskName, State

# 5. Check installation logs
Get-Content C:\Logs\configure-ad.log -Tail 30
```

## Manual Testing

### Test GPO - Notepad Auto-launch
1. Connect via RDP as `testuser@lab.local`
2. ✅ **Notepad will open automatically**

### Test GPO - C:\ Drive Restriction
1. Connect via RDP as `testuser@lab.local`
2. Open File Explorer > This PC
3. Try to access **C:\**
4. ✅ **Access denied**

## Project Structure

```
├── environments/
│   ├── bootstrap/          # Terraform state backend
│   └── dev/                # Development environment
│       ├── main.tf         # Main configuration
│       ├── provider.tf     # Providers and backend
│       └── outputs.tf      # Outputs
├── modules/
│   ├── s3/                 # S3 bucket module
│   ├── security-group/     # Security group module
│   └── windows-server/     # Windows EC2 + userdata module
└── scripts/
    └── configure-ad.ps1    # AD configuration script
```

## How the Automation Works

The entire server configuration is automated via **EC2 userdata** and **Windows RunOnce**:

1. **EC2 Launch** > Userdata runs:
   - Sets Administrator password
   - Copies `configure-ad.ps1` to `C:\Scripts\`
   - Registers a **RunOnce** entry to execute after every boot
   - Runs the script (installs AD + promotes to DC > **reboot**)

2. **Post-reboot** > RunOnce executes the script again:
   - Detects AD is already installed
   - Creates GPOs, OU, test user, scheduled task
   - Configures WinRM and disables firewall
   - Removes the RunOnce entry

3. **Done!** Everything is configured automatically.

## Security Note

The Security Group restricts RDP (port 3389) to the public IP of whoever runs `terraform apply`. If your IP changes, run `terraform apply` again to update it automatically.

## Clean Up

```bash
terraform destroy -auto-approve
```
