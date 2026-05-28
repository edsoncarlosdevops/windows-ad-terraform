variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde a EC2 sera criada"
  type        = string
}

variable "security_group_id" {
  description = "ID do security group"
  type        = string
}

variable "admin_password" {
  description = "Senha do administrador do Windows"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "Tipo da instancia"
  type        = string
  default     = "t3.large"
}
