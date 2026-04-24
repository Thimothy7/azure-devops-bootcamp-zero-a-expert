# FICHIER: backend.tf
terraform {
  backend "azurerm" {
    # Le backend AZURE STORAGE
    # Toutes ces valeurs sont OBLIGATOIRES
    
    resource_group_name  = "rg-terraform-state"  # RG contenant le storage
    storage_account_name = "stterraformstated3ffed4c"  # Nom de votre storage
    container_name       = "tfstate"              # Conteneur pour le state
    key                  = "prod.terraform.tfstate"  # Nom du fichier state
    
    # AUTHENTIFICATION (choisir une méthode)
    
    # Méthode 1: Access Key (simple)
    access_key = "adur2Bx/4fF5c21qC+li/YqXqQ6Ij+xoI4VZ00u0a0mZQ4t00Tevc0249KjUP6IAMcvj2SfDV12U+AStCgRhnw=="

  }
}