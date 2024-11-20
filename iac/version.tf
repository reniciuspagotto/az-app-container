terraform {
  required_version = ">=1.3.0, < 4.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.30.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
  }

  backend "azurerm" {
    resource_group_name  = "GHTFState"
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

provider "azapi" {
  use_oidc = true
}