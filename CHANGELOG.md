# Changelog

Les versions suivent le versionnement sémantique. Une version publiée ne doit jamais être déplacée ni réutilisée.

## v2.0.0

- Modernise la gestion des règles avec les ressources dédiées du provider AWS v6.
- Ajoute une réconciliation exclusive de l'ensemble des règles.
- Refuse le mélange entre CIDR IPv4 et Security Groups sources.
- Renforce la validation des identifiants AWS, des CIDR et des ports.
- Renomme `source_security_group_id` en `source_security_group_ids` pour simplifier la planification lorsque l'ID provient d'une ressource créée dans le même plan.
- Ajoute des tests de validation et un guide de commandes.

**Changement incompatible :** les projets consommateurs doivent remplacer `source_security_group_id` par `source_security_group_ids = ["sg-..."]` ou par une référence telle que `[module.sg_alb.security_group_id]`.
