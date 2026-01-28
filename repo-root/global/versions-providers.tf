terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.114"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.7"
    }
  }

  # Local backend keeps it portable; later we can use Azure Storage
  backend "local" {}
}

provider "azurerm" {
  features {}
  # no secrets needed for local runs (uses your az login)
}

provider "azuread" {
  # uses your Azure CLI context / device login by default
}