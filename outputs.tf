output "security_group_id" {
  description = "Identifiant du Security Group (a passer aux ASG, Launch Template, ALB...)."
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN du Security Group."
  value       = aws_security_group.this.arn
}

output "security_group_name" {
  description = "Nom genere du Security Group (prefixe + suffixe aleatoire)."
  value       = aws_security_group.this.name
}
