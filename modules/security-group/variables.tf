variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "allowed_rdp_cidr" {
  description = "CIDR liberado para RDP"
  type        = string
  default     = "0.0.0.0/0"
}
