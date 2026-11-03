output "security_group_id" {
  description = "Identifiant AWS du Security Group, à associer au Launch Template ou au Load Balancer."
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN AWS du Security Group."
  value       = aws_security_group.this.arn
}

output "security_group_name" {
  description = "Nom AWS réellement attribué au Security Group (préfixe plus suffixe généré)."
  value       = aws_security_group.this.name
}
