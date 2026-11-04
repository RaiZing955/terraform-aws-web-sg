# Le Security Group décrit le conteneur réseau. Les règles sont gérées par
# des ressources dédiées afin de disposer d'un identifiant par règle.
resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Security Group ${var.name} - géré par Terraform"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = var.name
  })

  # Si un attribut immuable impose de remplacer le groupe, créer d'abord
  # le nouveau SG réduit le risque d'interruption lors du remplacement.
  # Une simple modification de règle ne remplace normalement pas le SG.
  lifecycle {
    create_before_destroy = true
  }
}

# Une ressource de règle par CIDR IPv4. Les clés de for_each viennent des
# variables d'entrée, connues au moment de planifier.
resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = toset(var.allowed_cidrs)

  security_group_id = aws_security_group.this.id
  description       = "TCP ${var.ingress_port} depuis ${each.value}"
  ip_protocol       = "tcp"
  from_port         = var.ingress_port
  to_port           = var.ingress_port
  cidr_ipv4         = each.value
}

# Les index de la liste restent connus même si un ID de SG provient d'une
# ressource créée dans le même plan. Cela évite un for_each basé sur une
# valeur d'ID potentiellement inconnue pendant terraform plan.
resource "aws_vpc_security_group_ingress_rule" "source_security_group" {
  count = length(var.source_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "TCP ${var.ingress_port} depuis un Security Group autorisé"
  ip_protocol                  = "tcp"
  from_port                    = var.ingress_port
  to_port                      = var.ingress_port
  referenced_security_group_id = var.source_security_group_ids[count.index]
}

# Les règles de sortie sont limitées à des ports TCP explicitement choisis.
resource "aws_vpc_security_group_egress_rule" "tcp" {
  for_each = toset([for port in var.egress_ports : tostring(port)])

  security_group_id = aws_security_group.this.id
  description       = "TCP ${each.value} vers IPv4"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  cidr_ipv4         = "0.0.0.0/0"
}

# Prend en charge l'ensemble exclusif des règles du SG : lors d'un apply,
# les règles non déclarées dans ce module sont supprimées. Cela n'empêche
# pas une modification manuelle ; la réconciliation intervient au prochain
# terraform apply. La CI doit toujours exécuter un plan avant l'apply.
resource "aws_vpc_security_group_rules_exclusive" "this" {
  security_group_id = aws_security_group.this.id

  ingress_rule_ids = concat(
    [for rule in aws_vpc_security_group_ingress_rule.cidr : rule.id],
    [for rule in aws_vpc_security_group_ingress_rule.source_security_group : rule.id]
  )

  egress_rule_ids = [
    for rule in aws_vpc_security_group_egress_rule.tcp : rule.id
  ]
}
