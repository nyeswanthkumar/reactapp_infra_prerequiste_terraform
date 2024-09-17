variable "resource_group" {
  type        = string
  description = "azure resource group name for configurations"
}

variable "location" {
  type        = string
  description = "lcoation name"
}

variable "statefile_storage_account_name" {
  type        = string
  description = "storage account name to store Terraform statefile"
}

variable "statefile_storage_account_sku" {
  type        = string
  description = "storage account sku"
}

variable "react-app-config-kv-name" {
  type        = string
  description = "keyvault to store secrets required for Infrastructure provisioning"
}

variable "react-app-config-kv-sku" {
  type        = string
  description = "keyvault secrets sku"
}