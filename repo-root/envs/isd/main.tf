terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}

# Resolve mg-landingzones by name to get its ID
variable "mg_landingzones_name" { type = string, default = "mg-landingzones" }

data "azurerm_management_group" "lz" {
  name = var.mg_landingzones_name
} # Uses azurerm_management_group data source to fetch the MG id. [3](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)

module "isd_rbac" {
  source            = "../../modules/isd-rbac"
  landingzones_mg_id = data.azurerm_management_group.lz.id
}