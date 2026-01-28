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

  # Keep local backend for now so anyone can run from any PC
  backend "local" {}
}

provider "azurerm" {
  features {}  # REQUIRED by the azurerm provider
}

provider "azuread" {}