data "aws_ami" "windows" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "windows" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  get_password_data = false

  # EBS optimization for better performance
  ebs_optimized = true

  # Enable detailed monitoring
  monitoring = true

  # Metadata service - enforce IMDSv2 only
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Root volume encryption
  root_block_device {
    encrypted = true
  }

  # Longer timeout for Windows boot and AD configuration
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  user_data = <<-EOF
    <powershell>
    $ErrorActionPreference = 'Stop'
    $logFile = 'C:\Logs\userdata.log'

    Start-Transcript -Path $logFile -Append

    try {
        Write-Host "=== Creating directories ==="
    New-Item -ItemType Directory -Force -Path 'C:\Scripts' | Out-Null
    New-Item -ItemType Directory -Force -Path 'C:\Logs' | Out-Null

        Write-Host "=== Setting Administrator password ==="
    $password = ConvertTo-SecureString "${var.admin_password}" -AsPlainText -Force
    Set-LocalUser -Name Administrator -Password $password

        Write-Host "=== Copying configure-ad.ps1 script ==="
    @'
${file("${path.module}/../../scripts/configure-ad.ps1")}
'@ | Set-Content -Path 'C:\Scripts\configure-ad.ps1' -Encoding UTF8

        Write-Host "=== Registering RunOnce to execute script after every boot ==="
        $runOncePath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
        Set-ItemProperty -Path $runOncePath -Name 'ConfigureAD' -Value "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\configure-ad.ps1"

        Write-Host "=== Executing configure-ad.ps1 ==="
        & C:\Scripts\configure-ad.ps1
    }
    catch {
        Write-Host "=== ERROR: $_ ===" -ForegroundColor Red
        $_ | Out-File -FilePath 'C:\Logs\userdata-error.log' -Append
    }
    finally {
        Write-Host "=== Userdata completed ==="
        Stop-Transcript
    }

    Write-Host "=== Configuring WinRM and Firewall ==="
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
    netsh advfirewall set allprofiles state off
    </powershell>
  EOF

  tags = {
    Name        = "${var.environment}-windows-server"
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "windows-ad-terraform"
  }
}

