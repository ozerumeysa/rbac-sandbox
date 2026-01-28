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

  # Keep local state so anyone can run on their PC
  backend "local" {}
}

# Azure Resource Manager provider (REQUIRED: features {})
provider "azurerm" {
  features {}
}

# Entra ID (Azure AD) provider
provider "azuread" {}