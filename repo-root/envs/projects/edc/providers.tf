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

  backend "local" {}
}

provider "azurerm" {
  features {}  # REQUIRED by the AzureRM provider
}

provider "azuread" {}