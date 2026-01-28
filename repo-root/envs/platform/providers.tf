# envs/platform/providers.tf (root module for the platform environment)

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.57" } # v4.x required for PIM
    azuread = { source = "hashicorp/azuread", version = "~> 3.7" }
    time    = { source = "hashicorp/time",    version = "~> 0.9" }
  }
  backend "local" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id   # <—— explicit
  tenant_id       = var.tenant_id         # optional but recommended
}

provider "azuread" {}  # no subscription here; this targets Entra (tenant) APIs

# Variables for provider
variable "subscription_id" { type = string }
variable "tenant_id"       { type = string }