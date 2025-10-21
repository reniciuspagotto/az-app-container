terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.49.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.50.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "MvpConfInfraStatus"
    storage_account_name = "mvpconfinfra"
    container_name       = "mvpconftfstate"
    key                  = "azapp.tfstate"
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