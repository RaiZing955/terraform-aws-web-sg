# Revue du code initial

## Modifications appliquées

1. **Sources de trafic mutuellement exclusives** : le module exige maintenant des CIDR IPv4 ou des Security Groups sources, jamais les deux et jamais aucun.
2. **Validation CIDR IPv4** : `cidrnetmask` rejette IPv6 dans l'entrée IPv4, et `cidrsubnet(cidr, 0, 0) == cidr` impose un réseau canonique.
3. **Validation des IDs AWS** : `vpc_id` et les Security Groups source doivent suivre une forme d'identifiant AWS plutôt que seulement commencer par `vpc-` ou `sg-`.
4. **Ports entiers et doublons refusés** : les ports doivent être des entiers valides et les listes ne doivent pas contenir de doublons.
5. **Gestion moderne des règles** : remplacement des blocs `ingress`/`egress` en ligne par les ressources dédiées AWS, recommandées par la documentation du provider.
6. **Gestion exclusive** : ajout de `aws_vpc_security_group_rules_exclusive` pour réconcilier l'ensemble des règles déclarées lors d'un `apply`.
7. **Dépendance sur un SG calculé** : l'entrée devient `source_security_group_ids` (liste) et la règle est créée via `count`, dont la longueur est connue même lorsque l'ID vient d'une ressource du même plan.
8. **Documentation corrigée** : `create_before_destroy` est décrit comme protection lors du remplacement du SG, et non comme un déclencheur de remplacement à chaque changement de règle.
9. **Tests et CI** : ajout de tests ciblés sur les règles, les valeurs invalides, la politique de sources et IPv6 ; le workflow exécute formatage, validation et tests sans credentials AWS.
10. **Guide des commandes** : ajout de `GUIDE_COMMANDES.md` expliquant chaque commande, son utilité et ses limites.

## Point de migration à ne pas oublier

Le nom de variable d'entrée a changé : `source_security_group_id` devient `source_security_group_ids` (liste). Dans le dépôt NovaSphere, mettre à jour le bloc d'appel en conséquence, par exemple :

```hcl
source_security_group_ids = [module.sg_alb.security_group_id]
```

La version du provider requise est désormais `>= 6.0.0, < 7.0.0` car le module utilise les ressources dédiées de gestion des règles et la ressource de gestion exclusive. Après modification des contraintes, exécuter `terraform init -upgrade` dans le dossier de ce module, vérifier le diff du `.terraform.lock.hcl`, puis commiter le lockfile généré.

## Vérification effectuée

Le code a été relu statiquement et les exemples/tests ont été harmonisés. Terraform CLI n'était pas installé dans l'environnement de création ; les commandes `terraform fmt`, `terraform validate` et `terraform test` n'ont donc pas pu être exécutées ici. Le workflow GitHub Actions exécute ces contrôles lors du prochain push/PR. Ne considère pas le code comme certifié tant que ce workflow n'a pas réussi.
