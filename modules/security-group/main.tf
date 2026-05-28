resource "aws_security_group" "windows_rdp" {
  name        = "${var.environment}-windows-rdp-sg"
  description = "Libera RDP (3389) e WinRM (5985-5986)"
  vpc_id      = var.vpc_id

  # Em producao, trocar 0.0.0.0/0 pelo IP do seu escritorio/VPN
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_rdp_cidr]
    description = "RDP"
  }

  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.allowed_rdp_cidr]
    description = "WinRM"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    prevent_destroy = true # Seguranca: nao permite deletar sem querer
  }

  tags = { Name = "${var.environment}-windows-rdp-sg" }
}
