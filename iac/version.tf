terraform {
  required_version = ">=1.3.0, < 4.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0, < 4.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "GHTFState"
    storage_account_name = "rpftfstate"
    container_name       = "tfstate"
    key                  = "devapp.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  use_oidc = true
}