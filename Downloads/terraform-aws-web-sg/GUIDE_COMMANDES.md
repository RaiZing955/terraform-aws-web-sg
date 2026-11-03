# Guide des commandes — module Terraform Security Group

Ce guide explique ce que fait chaque commande, pourquoi l'exécuter et ce qu'il faut regarder dans le résultat.

## 1. Vérifier les outils

```bash
git --version
terraform version
```

- `git --version` vérifie que Git est installé.
- `terraform version` affiche la version locale de Terraform. Le dépôt demande Terraform 1.9 ou plus ; le workflow CI utilise une version testée explicitement.

## 2. Formater le code

```bash
terraform fmt -recursive
terraform fmt -check -recursive
```

- `terraform fmt -recursive` reformate les fichiers Terraform du dossier courant et de ses sous-dossiers.
- `-check` ne modifie pas les fichiers : la commande retourne une erreur si un fichier n'est pas correctement formaté. C'est la version adaptée à la CI.

Le formatage améliore la cohérence visuelle ; il ne prouve pas que la logique est correcte.

## 3. Initialiser Terraform

```bash
terraform init -backend=false
```

- `init` prépare le répertoire Terraform et télécharge les providers nécessaires.
- `-backend=false` demande de ne pas initialiser de backend distant. C'est adapté à ce dépôt de module qui teste sa configuration sans gérer d'infrastructure racine.
- Le fichier `.terraform.lock.hcl` mémorise la sélection du provider pour rendre l'installation plus reproductible.

Lorsque les contraintes du provider changent volontairement, utiliser `terraform init -upgrade`, examiner la mise à jour, puis versionner le lockfile régénéré.

## 4. Valider la configuration

```bash
terraform validate
```

Cette commande détecte des erreurs de syntaxe et de cohérence Terraform. Elle ne vérifie pas qu'un compte AWS existe, que les credentials fonctionnent ou qu'AWS autorisera réellement la création d'une ressource.

## 5. Lancer les tests

```bash
terraform test -no-color
```

- `terraform test` exécute les scénarios de `tests/security_group.tftest.hcl`.
- `mock_provider "aws" {}` simule le provider : les tests de plan n'appellent pas AWS et ne créent pas de ressources.
- `-no-color` rend la sortie plus adaptée aux logs de CI.

Les tests vérifient notamment que le port HTTP public est permis, que SSH/RDP sont refusés, que les CIDR sont valides et qu'une seule forme de source est donnée.

## 6. Comprendre les règles définies par le module

- `aws_security_group.this` crée l'objet Security Group dans le VPC indiqué.
- `aws_vpc_security_group_ingress_rule.cidr` crée une règle d'entrée par CIDR IPv4.
- `aws_vpc_security_group_ingress_rule.source_security_group` crée une règle d'entrée par Security Group source.
- `aws_vpc_security_group_egress_rule.tcp` crée une règle de sortie pour chaque port explicitement indiqué.
- `aws_vpc_security_group_rules_exclusive.this` maintient la liste configurée des règles d'entrée et de sortie ; les règles non déclarées sont réconciliées pendant `apply`.
- `create_before_destroy` demande à Terraform de créer la nouvelle ressource avant de supprimer l'ancienne lorsqu'un remplacement est nécessaire. Il ne transforme pas une simple modification de règle en remplacement du groupe.

## 7. Consommer le module depuis NovaSphere

Dans le dépôt principal, le bloc `module` sélectionne le dépôt Git et son tag. `vpc_id` transmet l'identifiant du VPC, `ingress_port` fixe le port Web et la source choisie limite les machines ou réseaux autorisés.

```hcl
module "sg_web" {
  source = "git::https://github.com/RaiZing955/terraform-aws-web-sg.git?ref=v2.0.0"

  name                      = "novasphere-dev-web"
  vpc_id                    = module.vpc.vpc_id
  ingress_port              = 80
  source_security_group_ids = [module.sg_alb.security_group_id]
  egress_ports              = [80, 443]
}
```

- `source` indique où télécharger le module et la version Git à utiliser.
- `name` donne un nom logique et un tag `Name`.
- `vpc_id` place le groupe dans le bon VPC.
- `ingress_port = 80` autorise le trafic HTTP entrant.
- `source_security_group_ids` permet uniquement au Security Group de l'ALB d'atteindre ce port.
- `egress_ports` limite les ports TCP sortants ; cette liste ne limite pas à elle seule les destinations, qui sont IPv4 `0.0.0.0/0` dans cette version.

Après avoir modifié un module versionné, publier un nouveau tag immuable et modifier la référence du projet principal. Ne pas déplacer un tag existant.

## 8. Commandes du dépôt principal (à ne lancer que lorsque l'infrastructure est prête)

```bash
terraform -chdir=envs/dev init
terraform -chdir=envs/dev validate
terraform -chdir=envs/dev plan
terraform -chdir=envs/dev apply
```

- `-chdir=envs/dev` exécute Terraform dans le dossier DEV sans changer manuellement de répertoire.
- `plan` compare la configuration et le state et propose les changements.
- `apply` applique les changements à AWS et peut créer des ressources facturées. Inspecter le plan avant d'approuver.

Pour les workflows exigés par le cahier des charges, l'`apply` de référence doit se faire dans GitHub Actions après merge, et non manuellement. Les commandes ci-dessus sont utiles pour le travail encadré et le débogage autorisé ; elles ne remplacent pas la démonstration CI/CD.

## 9. Règles d'hygiène

- Ne jamais commiter `terraform.tfstate`, `*.tfvars`, `*.tfplan`, `.env`, de clés ou de credentials.
- Ne pas coller un state ou des logs sensibles dans une issue publique.
- Lire les erreurs et corriger la cause plutôt que de retirer un contrôle de sécurité.
- Exécuter `terraform plan` avant un déploiement et comprendre les destructions/remplacements proposés.
