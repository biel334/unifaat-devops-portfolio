variable "aws_region" {
  description = "Região AWS (Learner Lab usa sempre us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo usado no nome dos recursos"
  type        = string
  default     = "technova"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nome do key pair existente (no Learner Lab: vockey)"
  type        = string
  default     = "vockey"
}

variable "app_port" {
  description = "Porta da aplicação"
  type        = number
  default     = 3000
}
