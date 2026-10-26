# Le module declare seulement les providers requis (jamais de bloc "provider") :
# la configuration (region, credentials, default_tags) vient du module racine.
terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
