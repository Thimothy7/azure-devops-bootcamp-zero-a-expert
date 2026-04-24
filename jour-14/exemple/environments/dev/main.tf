# ==========================================
# PROJET: Infrastructure 3-tiers pour WebApp
# ==========================================

terraform {
  required_version = "~> 1.11"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  
  backend "azurerm" {
    # Configuration via backend.conf
  }
}

provider "azurerm" {
  # features {
  #   resource_group {
  #     prevent_deletion_if_contains_resources = true
  #   }
  #   key_vault {
  #     purge_soft_delete_on_destroy    = true
  #     recover_soft_deleted_key_vaults = true
  #   }
  # }
}

# ==========================================
# LOCALS (calculs et constantes)
# ==========================================

locals {
  # Nommage standardisé
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Tags systématiques
  default_tags = {
    Environment   = var.environment
    ManagedBy     = "Terraform"
    Project       = var.project_name
    DeployedBy    = var.deployed_by
    CostCenter    = "FinOps-${upper(var.environment)}"
    Compliance    = "ISO27001"
  }
  
  # SKU par environnement
  app_service_sku = {
    dev     = "B1"
    staging = "S1"
    prod    = "P1V2"
  }
  
  # Capacité DB par environnement
  db_capacity = {
    dev     = 1
    staging = 2
    prod    = 4
  }
}

# ==========================================
# GROUPE DE RESSOURCES
# ==========================================

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.default_tags
}

# # ==========================================
# # RÉSEAU (VNET + SUBNETS)
# # ==========================================

# resource "azurerm_virtual_network" "vnet" {
#   name                = "vnet-${local.name_prefix}"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   address_space       = ["10.0.0.0/16"]
#   tags                = local.default_tags
# }

# resource "azurerm_subnet" "web" {
#   name                 = "snet-web"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.0.1.0/24"]
  
#   # Délégation pour App Service
#   delegation {
#     name = "webapp-delegation"
#     service_delegation {
#       name    = "Microsoft.Web/serverFarms"
#       actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
#     }
#   }
# }

# resource "azurerm_subnet" "db" {
#   name                 = "snet-db"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.0.2.0/24"]
  
#   # Service endpoint pour Azure SQL
#   service_endpoints = ["Microsoft.Sql"]
# }

# # ==========================================
# # BASE DE DONNÉES SQL
# # ==========================================

# resource "azurerm_mssql_server" "sql" {
#   name                         = "sql-${local.name_prefix}${random_string.suffix.result}"
#   resource_group_name          = azurerm_resource_group.rg.name
#   location                     = azurerm_resource_group.rg.location
#   version                      = "12.0"
#   administrator_login          = var.sql_admin_username
#   administrator_login_password = var.sql_admin_password  # Sensitive
  
#   tags = local.default_tags
# }

# # Règle firewall pour permettre accès depuis les services Azure
# resource "azurerm_mssql_firewall_rule" "allow_azure" {
#   name             = "AllowAzureServices"
#   server_id        = azurerm_mssql_server.sql.id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "0.0.0.0"
# }

# # Base de données
# resource "azurerm_mssql_database" "appdb" {
#   name           = "appdb"
#   server_id      = azurerm_mssql_server.sql.id
#   sku_name       = "GP_Gen5_${local.db_capacity[var.environment]}"
#   max_size_gb    = 32
  
#   # Configuration avancée
#   threat_detection_policy {
#     state                = "Enabled"
#     retention_days       = 30
#     email_addresses      = ["security@company.com"]
#     email_account_admins = true
#   }
  
#   tags = local.default_tags
# }

# # ==========================================
# # APPLICATION WEB (APP SERVICE)
# # ==========================================

# resource "azurerm_service_plan" "asp" {
#   name                = "asp-${local.name_prefix}"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   os_type             = "Linux"
#   sku_name            = local.app_service_sku[var.environment]
  
#   tags = local.default_tags
# }

# resource "azurerm_linux_web_app" "webapp" {
#   name                = "app-${local.name_prefix}${random_string.suffix.result}"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   service_plan_id     = azurerm_service_plan.asp.id
#   https_only          = true
  
#   # Configuration du site
#   site_config {
#     application_stack {
#       dotnet_version = "8.0"
#     }
    
#     # Always on pour production
#     always_on = var.environment == "prod" ? true : false
    
#     # 32-bit en dev, 64-bit en prod
#     use_32_bit_worker = var.environment == "dev" ? true : false
    
#     # Min TLS 1.2
#     minimum_tls_version = "1.2"
#   }
  
#   # Application settings (secrets)
#   app_settings = {
#     "ConnectionStrings:DefaultConnection" = "Server=${azurerm_mssql_server.sql.fully_qualified_domain_name};Database=${azurerm_mssql_database.appdb.name};User Id=${azurerm_mssql_server.sql.administrator_login};Password=${azurerm_mssql_server.sql.administrator_login_password};"
#     "ASPNETCORE_ENVIRONMENT" = var.environment
#   }
  
#   # Identité managée (pour accès aux secrets)
#   identity {
#     type = "SystemAssigned"
#   }
  
#   tags = local.default_tags
# }

# # ==========================================
# # KEY VAULT POUR SECRETS D'APP
# # ==========================================

# resource "azurerm_key_vault" "kv" {
#   name                = "kv-${local.name_prefix}${random_string.suffix.result}"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   sku_name            = "standard"
  
#   soft_delete_retention_days = 7
#   purge_protection_enabled   = false  # Dev only, true pour prod
  
#   tags = local.default_tags
# }

# # Politique d'accès pour App Service
# resource "azurerm_key_vault_access_policy" "webapp" {
#   key_vault_id = azurerm_key_vault.kv.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = azurerm_linux_web_app.webapp.identity[0].principal_id
  
#   secret_permissions = ["Get", "List"]
# }

# # Secret stocké dans Key Vault
# resource "azurerm_key_vault_secret" "api_key" {
#   name         = "APIKey"
#   value        = random_password.api_key.result
#   key_vault_id = azurerm_key_vault.kv.id
  
#   tags = local.default_tags
# }

# resource "random_password" "api_key" {
#   length  = 32
#   special = true
#   min_special = 2
# }

# # ==========================================
# # OUTPUTS (Informations de déploiement)
# # ==========================================

# output "webapp_url" {
#   description = "URL de l'application web"
#   value       = "https://${azurerm_linux_web_app.webapp.default_hostname}"
# }

# output "sql_server_fqdn" {
#   description = "Nom complet du serveur SQL"
#   value       = azurerm_mssql_server.sql.fully_qualified_domain_name
# }

# output "key_vault_id" {
#   description = "ID du Key Vault"
#   value       = azurerm_key_vault.kv.id
# }