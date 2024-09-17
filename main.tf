# Prerequiste Infrastructure provisioning, Keyvault and 
# Storage Account resources to store secrets in keyvault and store statefile in storage account

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.0.1"
    }
  }
}

provider "azurerm" {
  tenant_id       = "azure tenant id"
  subscription_id = "azure subscription id"
  client_id       = "azure AD app registration client id"
  client_secret   = ""
  features {

  }
}

# Declare local variables
locals {
  tags = {
    ProjectName = "react-data-app"
    Environment = "Development"
    Owner = "Dev Team"
  }
  
}

# Configuration of AzureRM provider
data "azurerm_client_config" "current_rm_config" {}

# Azure Resouce Group Creation
resource "azurerm_resource_group" "react_app_rg" {
  name     = var.resource_group
  location = var.location
  tags = local.tags
}

# Azure keyvault to store React Data App secrets and will read this values in actual infra provising (reactapp_infra)
resource "azurerm_key_vault" "react-app-config-kv" {
  name                        = var.react-app-config-kv-name
  location                    = azurerm_resource_group.react_app_rg.location
  resource_group_name         = azurerm_resource_group.react_app_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current_rm_config.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                     = var.react-app-config-kv-sku

  access_policy {
    tenant_id = data.azurerm_client_config.current_rm_config.tenant_id
    object_id = data.azurerm_client_config.current_rm_config.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
  }
}

# Demo purpose configured secrets information here, generally we don't keep any passwords in code or script level, 
# admins configures secrets in Azure keyvault in secure way.
resource "azurerm_key_vault_secret" "react-app-mssql-server-username" {
  name         = "react-app-mssql-server-username"
  value        = "reactappadmin"
  key_vault_id = azurerm_key_vault.react-app-config-kv.id
}

resource "azurerm_key_vault_secret" "react-app-mssql-server-password" {
  name         = "react-app-mssql-server-password"
  value        = "!djk@mBn%yub!ed" 
  key_vault_id = azurerm_key_vault.react-app-config-kv.id
}

output "sqlserver_username" {
  value = azurerm_key_vault_secret.react-app-mssql-server-username.value
  sensitive = true
}

# Azure Storage Account to store and track Azure Infrastructure Statefile instead of storing in local systems.
resource "azurerm_storage_account" "statefile_storage_account" {
  name                     = var.statefile_storage_account_name
  resource_group_name      = azurerm_resource_group.react_app_rg.name
  location                 = azurerm_resource_group.react_app_rg.location
  account_tier             = var.statefile_storage_account_sku
  account_replication_type = "LRS"
  blob_properties {
    versioning_enabled = true
    change_feed_enabled = true
    delete_retention_policy {
      days = 30
    }
    restore_policy {
      days = 7
    }
  }
  tags = {
    environment = "StateFile Config"
  }
}

resource "azurerm_storage_container" "tfstate-container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.statefile_storage_account.name
  container_access_type = "private"
}

output "storage_key_output" {
   value = azurerm_storage_account.statefile_storage_account.primary_access_key
   sensitive = true
} 