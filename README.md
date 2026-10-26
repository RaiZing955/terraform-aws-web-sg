# terraform-aws-web-sg

Module Terraform de l'équipe NovaSphere : un **Security Group web fermé par défaut**.

- un seul port TCP ouvert en entrée (jamais 22 ni 3389) ;
- source = CIDR **ou** autre Security Group (par exemple le SG de l'ALB) ;
- `0.0.0.0/0` accepté uniquement sur les ports 80 et 443 ;
- sortie limitée à des ports précis (80 et 443 par défaut), jamais « tout » ;
- règles **en ligne** : Terraform gère la liste complète, une règle ajoutée à la main est détectée comme dérive ;
- `create_before_destroy` : un changement de règle ne coupe pas le service.

## Utilisation

    module "sg_alb" {
      source = "git::https://github.com/RaiZing955/terraform-aws-web-sg.git?ref=v1.0.0"

      name          = "novasphere-dev-alb"
      vpc_id        = module.vpc.vpc_id
      ingress_port  = 80
      allowed_cidrs = ["0.0.0.0/0"]
      egress_ports  = [80]
    }

    module "sg_web" {
      source = "git::https://github.com/RaiZing955/terraform-aws-web-sg.git?ref=v1.0.0"

      name                     = "novasphere-dev-web"
      vpc_id                   = module.vpc.vpc_id
      ingress_port             = 80
      source_security_group_id = module.sg_alb.security_group_id
    }

## Entrées / sorties

Voir `variables.tf` (types et validations) et `outputs.tf` (`security_group_id`, `security_group_arn`, `security_group_name`).

## Tests

    terraform init -backend=false
    terraform test        # provider simulé : aucun credential AWS nécessaire

7 tests : nommage, refus de SSH, refus de `0.0.0.0/0` hors ports web, CIDR invalide, VPC mal formé, source absente.
Ils tournent dans la CI (`.github/workflows/test.yml`) à chaque pull request.

## Versions

Un tag par évolution (`v1.0.0`, `v1.1.0`, ...), **jamais modifié après publication**.
Les environnements pointent sur le **hash de commit** du tag, qui ne peut pas être déplacé.
