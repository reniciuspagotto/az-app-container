terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.116.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.30.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "MvpConfOnline"
    storage_account_name = "rpftfstate"
    container_name       = "tfstate"
    key                  = "devapp.tfstate"
    use_oidc = true
  }
}

provider "azurerm" {
  use_oidc = true
  features {}
}

provider "azuread" {
}

data "azurerm_client_config" "current" {}