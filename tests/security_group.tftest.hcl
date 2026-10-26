# Tests du module, sans AWS : le provider est simule (mock_provider).
# Lancer : terraform init -backend=false && terraform test
mock_provider "aws" {}

variables {
  name          = "demo-alb"
  vpc_id        = "vpc-0123456789abcdef0"
  ingress_port  = 80
  allowed_cidrs = ["0.0.0.0/0"]
}

run "http_public_valide" {
  command = plan

  assert {
    condition     = aws_security_group.this.name_prefix == "demo-alb-"
    error_message = "Le nom doit etre prefixe par var.name (necessaire a create_before_destroy)."
  }

  assert {
    condition     = aws_security_group.this.tags["Name"] == "demo-alb"
    error_message = "Le tag Name doit valoir var.name."
  }
}

run "source_security_group_valide" {
  command = plan

  variables {
    name                     = "demo-web"
    allowed_cidrs            = []
    source_security_group_id = "sg-0123456789abcdef0"
  }

  assert {
    condition     = aws_security_group.this.vpc_id == "vpc-0123456789abcdef0"
    error_message = "Le Security Group doit etre cree dans le VPC fourni."
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

run "refuse_aucune_source" {
  command = plan

  variables {
    allowed_cidrs = []
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
