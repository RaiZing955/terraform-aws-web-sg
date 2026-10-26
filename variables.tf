variable "name" {
  description = "Nom logique du Security Group (ex : novasphere-dev-alb)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name))
    error_message = "name doit faire 3 a 40 caracteres : minuscules, chiffres et tirets."
  }
}

variable "vpc_id" {
  description = "Identifiant du VPC dans lequel creer le Security Group."
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "vpc_id doit commencer par vpc-."
  }
}

variable "ingress_port" {
  description = "Port TCP ouvert en entree (un seul port par Security Group)."
  type        = number

  validation {
    condition = (
      var.ingress_port >= 1 &&
      var.ingress_port <= 65535 &&
      !contains([22, 3389], var.ingress_port)
    )
    error_message = "ingress_port doit etre entre 1 et 65535 et ne peut pas etre 22 (SSH) ni 3389 (RDP) : l'administration passe par Session Manager."
  }
}

variable "allowed_cidrs" {
  description = "CIDR autorises en entree. 0.0.0.0/0 n'est accepte que pour les ports 80 et 443."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Chaque element de allowed_cidrs doit etre un CIDR valide (ex : 10.0.0.0/16)."
  }

  validation {
    condition     = !contains(var.allowed_cidrs, "0.0.0.0/0") || contains([80, 443], var.ingress_port)
    error_message = "0.0.0.0/0 n'est autorise que sur les ports 80 et 443."
  }

  validation {
    condition     = length(var.allowed_cidrs) > 0 || var.source_security_group_id != null
    error_message = "Fournir au moins une source : allowed_cidrs ou source_security_group_id."
  }
}

variable "source_security_group_id" {
  description = "Security Group autorise en entree (ex : celui de l'ALB). Prefere a un CIDR quand c'est possible."
  type        = string
  default     = null

  validation {
    condition     = var.source_security_group_id == null || can(regex("^sg-", var.source_security_group_id))
    error_message = "source_security_group_id doit commencer par sg-."
  }
}

variable "egress_ports" {
  description = "Ports TCP autorises en sortie vers Internet. Jamais de regle 'tout autoriser'."
  type        = list(number)
  default     = [80, 443]

  validation {
    condition     = alltrue([for p in var.egress_ports : p >= 1 && p <= 65535])
    error_message = "Chaque port de egress_ports doit etre entre 1 et 65535."
  }
}

variable "tags" {
  description = "Tags supplementaires (les default_tags du provider s'appliquent deja)."
  type        = map(string)
  default     = {}
}
