variable "name" {
  description = "Préfixe lisible du Security Group et valeur du tag Name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$", var.name))
    error_message = "name doit contenir 3 à 40 caractères : minuscules, chiffres ou tirets, sans tiret au début ni à la fin."
  }
}

variable "vpc_id" {
  description = "Identifiant du VPC dans lequel créer le Security Group."
  type        = string

  validation {
    condition     = can(regex("^vpc-([0-9a-fA-F]{8}|[0-9a-fA-F]{17})$", var.vpc_id))
    error_message = "vpc_id doit être un identifiant VPC AWS valide (vpc- suivi de 8 ou 17 caractères hexadécimaux)."
  }
}

variable "ingress_port" {
  description = "Port TCP unique autorisé en entrée. L'administration SSH/RDP doit utiliser un mécanisme dédié."
  type        = number

  validation {
    condition     = (
      var.ingress_port == floor(var.ingress_port) &&
      var.ingress_port >= 1 &&
      var.ingress_port <= 65535 &&
      !contains([22, 3389], var.ingress_port)
    )
    error_message = "ingress_port doit être un entier entre 1 et 65535, différent de 22 (SSH) et de 3389 (RDP)."
  }
}

variable "allowed_cidrs" {
  description = "Sources IPv4 autorisées en entrée. À utiliser à la place de source_security_group_ids, jamais en même temps."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([
      for cidr in var.allowed_cidrs :
      can(cidrnetmask(cidr)) && try(cidrsubnet(cidr, 0, 0) == cidr, false)
    ])
    error_message = "Chaque valeur de allowed_cidrs doit être un réseau IPv4 CIDR valide et canonique (ex. 10.20.0.0/16)."
  }

  validation {
    condition     = length(var.allowed_cidrs) == length(toset(var.allowed_cidrs))
    error_message = "allowed_cidrs ne doit pas contenir de doublons."
  }

  validation {
    condition     = !contains(var.allowed_cidrs, "0.0.0.0/0") || contains([80, 443], var.ingress_port)
    error_message = "La source publique 0.0.0.0/0 est uniquement autorisée pour HTTP (80) ou HTTPS (443)."
  }

  validation {
    condition     = (
      (length(var.allowed_cidrs) > 0) !=
      (length(var.source_security_group_ids) > 0)
    )
    error_message = "Définir exactement un type de source : allowed_cidrs OU source_security_group_ids."
  }
}

variable "source_security_group_ids" {
  description = "Liste des Security Groups autorisés à joindre le port d'entrée. À utiliser à la place de allowed_cidrs."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([
      for sg_id in var.source_security_group_ids :
      can(regex("^sg-([0-9a-fA-F]{8}|[0-9a-fA-F]{17})$", sg_id))
    ])
    error_message = "Chaque élément de source_security_group_ids doit être un identifiant Security Group AWS valide (sg- suivi de 8 ou 17 caractères hexadécimaux)."
  }

  validation {
    condition     = length(var.source_security_group_ids) == length(toset(var.source_security_group_ids))
    error_message = "source_security_group_ids ne doit pas contenir de doublons."
  }
}

variable "egress_ports" {
  description = "Ports TCP autorisés en sortie vers 0.0.0.0/0. Une liste vide bloque les nouvelles connexions sortantes gérées par ce module."
  type        = list(number)
  default     = [80, 443]

  validation {
    condition     = alltrue([
      for port in var.egress_ports :
      port          = = floor(port) && port >= 1 && port <= 65535
    ])
    error_message = "Chaque port de egress_ports doit être un entier compris entre 1 et 65535."
  }

  validation {
    condition     = length(var.egress_ports) == length(toset(var.egress_ports))
    error_message = "egress_ports ne doit pas contenir de doublons."
  }
}

variable "tags" {
  description = "Tags complémentaires. Le module impose sa propre valeur pour le tag Name."
  type        = map(string)
  default     = {}
}
