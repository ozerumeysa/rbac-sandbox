// repo-root/providers.tf (or repo-root/global/providers.tf)

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

  // Keep local backend initially so it runs on any PC.
  backend "local" {}
}

provider "azurerm" {
  features {}  // <-- REQUIRED
}

provider "azuread" {}