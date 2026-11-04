# Tests de plan avec un provider AWS simulé : ils ne créent aucune ressource AWS.
# Depuis la racine du module : terraform init -backend=false && terraform test
mock_provider "aws" {}

variables {
  name          = "demo-alb"
  vpc_id        = "vpc-0123456789abcdef0"
  ingress_port  = 80
  allowed_cidrs = ["0.0.0.0/0"]
  egress_ports  = [80, 443]
}

run "accepte_http_public" {
  command = plan

  assert {
    condition     = aws_security_group.this.name_prefix == "demo-alb-"
    error_message = "Le Security Group doit utiliser le préfixe demandé."
  }

  assert {
    condition     = aws_security_group.this.tags["Name"] == "demo-alb"
    error_message = "Le tag Name doit reprendre le nom logique fourni."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.cidr["0.0.0.0/0"].from_port == 80
    error_message = "La règle HTTP doit ouvrir le port 80."
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.tcp) == 2
    error_message = "Deux règles de sortie sont attendues pour les ports 80 et 443."
  }
}

run "accepte_source_security_group" {
  command = plan

  variables {
    name                      = "demo-web"
    allowed_cidrs             = []
    source_security_group_ids = ["sg-0123456789abcdef0"]
    egress_ports              = [80, 443]
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.source_security_group[0].referenced_security_group_id == "sg-0123456789abcdef0"
    error_message = "Le trafic entrant doit être lié au Security Group source fourni."
  }
}

run "refuse_ssh" {
  command = plan

  variables {
    ingress_port  = 22
    allowed_cidrs = ["10.0.0.0/16"]
  }

  expect_failures = [var.ingress_port]
}

run "refuse_rdp" {
  command = plan

  variables {
    ingress_port  = 3389
    allowed_cidrs = ["10.0.0.0/16"]
  }

  expect_failures = [var.ingress_port]
}

run "refuse_internet_ouvert_hors_web" {
  command = plan

  variables {
    ingress_port  = 8080
    allowed_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.allowed_cidrs]
}

run "refuse_cidr_invalide" {
  command = plan

  variables {
    allowed_cidrs = ["10.0.0.0/33"]
  }

  expect_failures = [var.allowed_cidrs]
}

run "refuse_cidr_ipv6_dans_la_liste_ipv4" {
  command = plan

  variables {
    allowed_cidrs = ["2001:db8::/32"]
  }

  expect_failures = [var.allowed_cidrs]
}

run "refuse_source_absente" {
  command = plan

  variables {
    allowed_cidrs             = []
    source_security_group_ids = []
  }

  expect_failures = [var.allowed_cidrs]
}

run "refuse_deux_types_de_sources" {
  command = plan

  variables {
    allowed_cidrs             = ["10.0.0.0/16"]
    source_security_group_ids = ["sg-0123456789abcdef0"]
  }

  expect_failures = [var.allowed_cidrs]
}

run "refuse_vpc_mal_forme" {
  command = plan

  variables {
    vpc_id = "pas-un-vpc"
  }

  expect_failures = [var.vpc_id]
}
