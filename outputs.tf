output "ec2_public_ip" {
  description = "IP público da EC2 (usar no secret EC2_HOST)"
  value       = aws_instance.api.public_ip
}

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.api.repository_url
}

output "health_url" {
  description = "URL do health check"
  value       = "http://${aws_instance.api.public_ip}:${var.app_port}/health"
}
