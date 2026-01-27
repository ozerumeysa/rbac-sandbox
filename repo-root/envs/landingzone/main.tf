terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}

# If you know the MG name and want to look up its ID:
variable "mg_landingzones_name" {
  description = "Name (not display name) of mg-landingzones"
  type        = string
  default     = "mg-landingzones"
}

data "azurerm_management_group" "lz" {
  name = var.mg_landingzones_name
}
# (Lookup by MG name is supported; you get the MG resource id for use as scope.) [3](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)

module "landingzone_rbac" {
  source             = "../../modules/landingzone-rbac"
  mg_landingzones_id = data.azurerm_management_group.lz.id
}