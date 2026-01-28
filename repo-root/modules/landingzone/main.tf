terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}


# Inputs

variable "parent_mg_id" {
  description = "Resource ID of the parent MG (Tenant Root)."
  type        = string
}

variable "mg_name" {
  description = "Name for the Landing Zones MG."
  type        = string
  default     = "mg-landingzone"
}


# Create mg-landingzone under Tenant Root

resource "azurerm_management_group" "lz" {
  name                       = var.mg_name
  display_name               = var.mg_name
  parent_management_group_id = var.parent_mg_id
}
# Management groups are created/nested via azurerm_management_group. [1](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)


# Entra (AAD) security groups

locals {
  lz_groups = {
    owner  = "LandingZone-Owner"
    reader = "LandingZone-Reader"
  }
}

resource "azuread_group" "lz" {
  for_each                = local.lz_groups
  display_name            = each.value
  security_enabled        = true
  prevent_duplicate_names = true
}
# Entra security groups are created via azuread_group. [2](https://shisho.dev/dojo/providers/azurerm/Management/azurerm-management-group/)


# RBAC for Landing Zone personas

locals {
  lz_rbac = [
    # Owner
    { group = "owner",  role = "Contributor" },
    { group = "owner",  role = "EventGrid Contributor" },
    { group = "owner",  role = "Log Analytics Contributor" },
    { group = "owner",  role = "Monitoring Contributor" },
    { group = "owner",  role = "Tag Contributor" },

    # Reader
    { group = "reader", role = "Reader" }
  ]
}

resource "azurerm_role_assignment" "lz_assign" {
  for_each = { for idx, item in local.lz_rbac : idx => item }

  scope                = azurerm_management_group.lz.id
  role_definition_name = each.value.role
  principal_id         = azuread_group.lz[each.value.group].object_id
}
# RBAC assignments use azurerm_role_assignment with scope, role_definition_name, principal_id. [3](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/landing-zone-governance)


# Outputs

output "mg_landingzone_id" { value = azurerm_management_group.lz.id }

output "group_ids" {
  value = { for k, g in azuread_group.lz : k => g.object_id }
}