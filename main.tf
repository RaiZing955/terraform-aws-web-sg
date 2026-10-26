# Regles EN LIGNE (blocs ingress/egress) et non en ressources separees : avec des regles en ligne,
# Terraform gere la liste COMPLETE des regles. Une regle ajoutee a la main dans la console est donc
# detectee comme une derive par `plan`, puis retiree par `apply`.
#
# name_prefix + create_before_destroy : un Security Group utilise ne peut pas etre detruit tant
# qu'il est attache ; on cree le nouveau avant de supprimer l'ancien.
resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Security Group ${var.name} (gere par Terraform)"
  vpc_id      = var.vpc_id

  # Entree depuis des CIDR (une regle par CIDR)
  dynamic "ingress" {
    for_each = toset(var.allowed_cidrs)

    content {
      description = "TCP ${var.ingress_port} depuis ${ingress.value}"
      from_port   = var.ingress_port
      to_port     = var.ingress_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Entree depuis un autre Security Group (ex : celui de l'ALB), s'il est fourni
  dynamic "ingress" {
    for_each = var.source_security_group_id == null ? [] : [var.source_security_group_id]

    content {
      description     = "TCP ${var.ingress_port} depuis le Security Group source"
      from_port       = var.ingress_port
      to_port         = var.ingress_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # Sortie limitee a des ports precis (jamais "tout")
  dynamic "egress" {
    for_each = toset(var.egress_ports)

    content {
      description = "Sortie TCP ${egress.value}"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}
