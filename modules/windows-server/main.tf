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
  vpc_security_group_ids = [var.security_group_id]

  get_password_data = true

  user_data = <<-EOF
    <powershell>
    $password = ConvertTo-SecureString "${var.admin_password}" -AsPlainText -Force
    Set-LocalUser -Name Administrator -Password $password

    # Configura WinRM para aceitar conexoes
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'

    # Desliga firewall para nao bloquear nada
    netsh advfirewall set allprofiles state off
    </powershell>
  EOF

  tags = { Name = "${var.environment}-windows-server" }
}
