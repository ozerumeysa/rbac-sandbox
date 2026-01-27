terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}

# 0) INPUTS

variable "mg_landingzones_id" {
  description = "Resource ID of mg-landingzones management group"
  type        = string
}


# 1) CREATE ENTRA GROUPS
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
# (Creates standard Entra security groups suitable for Azure RBAC.) [1](https://shisho.dev/dojo/providers/azurerm/Management/azurerm-management-group/)


# 2) RBAC ASSIGNMENTS AT mg-landingzones

locals {
  # Owner permissions (infra + ops), Reader (visibility)
  lz_rbac = [
    # LandingZone-Owner
    { group = "owner",  role = "Contributor" },
    { group = "owner",  role = "EventGrid Contributor" },
    { group = "owner",  role = "Log Analytics Contributor" },
    { group = "owner",  role = "Monitoring Contributor" },
    { group = "owner",  role = "Tag Contributor" },

    # LandingZone-Reader
    { group = "reader", role = "Reader" }
  ]
}

resource "azurerm_role_assignment" "lz_assign" {
  for_each = {
    for idx, item in local.lz_rbac : idx => item
  }

  scope                = var.mg_landingzones_id
  role_definition_name = each.value.role
  principal_id         = azuread_group.lz[each.value.group].object_id
}
# (Role assignment is done with azurerm_role_assignment using scope, role_definition_name, principal_id.) [2](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/landing-zone-governance)


# 3) OUTPUTS

output "group_ids" {
  value = { for k, g in azuread_group.lz : k => g.object_id }
}

output "mg_landingzones_id" {
  value = var.mg_landingzones_id
}