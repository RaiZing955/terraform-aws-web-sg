# terraform-aws-web-sg

Module Terraform réutilisable pour créer un **Security Group AWS avec des règles d'entrée et de sortie explicitement autorisées**. Il est destiné au projet NovaSphere et peut être utilisé pour le Security Group public de l'ALB ou celui des instances Web.

## Principes de sécurité

- Une seule source de trafic entrant est autorisée par configuration : des CIDR IPv4 **ou** des Security Groups sources.
- Le trafic entrant utilise TCP et un seul port configurable.
- Les ports 22 (SSH) et 3389 (RDP) sont refusés en entrée : l'administration doit utiliser un mécanisme dédié, par exemple AWS Systems Manager Session Manager lorsque le compte et le profil IAM le permettent.
- La source publique `0.0.0.0/0` est acceptée uniquement sur les ports 80 et 443.
- Les sorties TCP sont limitées à `egress_ports` (80 et 443 par défaut) vers IPv4. Les sorties IPv6 ne sont pas gérées par cette version.
- Les règles utilisent les ressources AWS dédiées `aws_vpc_security_group_ingress_rule` et `aws_vpc_security_group_egress_rule`.
- `aws_vpc_security_group_rules_exclusive` maintient un ensemble exclusif de règles : les règles non déclarées sont réconciliées lors d'un `terraform apply`.
- Aucun provider, région, credential ou VPC n'est codé en dur dans le module. Le projet racine configure le provider et lui transmet l'identifiant du VPC.

> Attention : le module est volontairement strict. Il n'ouvre pas SSH, et les règles de sortie par défaut permettent HTTP/HTTPS vers Internet IPv4 uniquement. Adapte les règles aux dépendances réelles de l'application plutôt que d'ouvrir tous les ports.

## Prérequis

- Terraform `>= 1.9.0`.
- Provider AWS `>= 6.0.0, < 7.0.0`.
- Un provider AWS configuré dans le projet racine.
- Un VPC existant et les autorisations AWS nécessaires.

Le module ne configure pas les credentials. En Learner Lab, ceux-ci doivent être fournis par la session AWS temporaire et ne doivent jamais être inscrits dans Git.

## Exemples d'utilisation

### 1. Security Group public de l'ALB

```hcl
module "sg_alb" {
  source = "git::https://github.com/RaiZing955/terraform-aws-web-sg.git?ref=v2.0.0"

  name         = "novasphere-dev-alb"
  vpc_id       = module.vpc.vpc_id
  ingress_port = 80
  allowed_cidrs = [
    "0.0.0.0/0"
  ]

  # L'ALB ne doit transmettre le trafic qu'au port HTTP des instances.
  egress_ports = [80]

  tags = {
    Project     = "NovaSphere"
    Environment = "dev"
  }
}
```

### 2. Security Group des instances Web

```hcl
module "sg_web" {
  source = "git::https://github.com/RaiZing955/terraform-aws-web-sg.git?ref=v2.0.0"

  name                      = "novasphere-dev-web"
  vpc_id                    = module.vpc.vpc_id
  ingress_port              = 80
  source_security_group_ids = [module.sg_alb.security_group_id]

  # À adapter aux dépendances réelles : dépôts de paquets, SSM, etc.
  egress_ports = [80, 443]

  tags = {
    Project     = "NovaSphere"
    Environment = "dev"
  }
}
```

La liste `source_security_group_ids` est intentionnelle : sa longueur est connue pendant la planification, même si l'identifiant du SG provient d'une ressource créée dans le même plan Terraform.

### Sorties disponibles

| Output | Utilisation |
|---|---|
| `security_group_id` | Associer le SG au Launch Template, à une instance ou à un Load Balancer. |
| `security_group_arn` | Référence ARN pour d'autres ressources ou outils. |
| `security_group_name` | Nom réellement créé par AWS, suffixe compris. |

## Commandes pour le développeur

À exécuter depuis la racine de ce dépôt :

```bash
# Formater les fichiers Terraform
terraform fmt -recursive

# Télécharger les providers et préparer le répertoire de travail
terraform init -backend=false

# Vérifier la cohérence de la configuration
terraform validate

# Exécuter les tests avec un provider AWS simulé
terraform test

# Vérifier le résultat dans la CI (commande sans modification de fichiers)
terraform fmt -check -recursive
```

Ces tests n'appliquent pas l'infrastructure et ne nécessitent pas de credentials AWS. Ils vérifient notamment les entrées acceptées/refusées et les règles prévues au plan. La CI ne remplace pas un test d'intégration AWS, qui doit être fait séparément dans un compte autorisé.

## Gestion des versions

- Créer un tag pour chaque version validée (`v1.0.0`, `v1.1.0`, etc.).
- Ne jamais déplacer ni réutiliser un tag publié.
- Après une évolution, publier un nouveau tag puis mettre à jour `ref=` dans les environnements consommateurs.
- Pour que la CI soit reproductible, conserver le fichier `.terraform.lock.hcl` et le mettre à jour avec Terraform lorsque les contraintes ou versions de providers changent.

## Limites connues

- Ce module n'active pas IPv6. Les CIDR d'entrée doivent être des réseaux IPv4 canoniques.
- Les règles de sortie vont vers `0.0.0.0/0`, mais uniquement sur les ports choisis. Pour une politique de sortie plus stricte, il faudrait aussi paramétrer les destinations et tenir compte des endpoints AWS nécessaires.
- Une règle manuelle ajoutée dans la console peut exister jusqu'à la prochaine réconciliation par `terraform apply`. Un `terraform plan` de dérive seul ne doit pas être présenté comme un mécanisme de remédiation.
- `create_before_destroy` aide lors du remplacement du Security Group lui-même ; il ne provoque pas le remplacement du SG lors d'un simple changement de règle.
