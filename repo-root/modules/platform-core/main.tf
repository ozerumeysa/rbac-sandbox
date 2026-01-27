terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}


# 0) INPUT VARIABLES

variable "mg_platform_id"      { type = string }
variable "mg_identity_id"      { type = string }
variable "mg_connectivity_id"  { type = string }
variable "mg_management_id"    { type = string }


# 1) CREATE ENTRA SECURITY GROUPS

locals {
  groups = {
    platform_owners               = "Platform-Owners"
    platform_identity_admins      = "Platform-Identity-Admins"
    platform_identity_secops      = "Platform-Identity-SecurityOps"
    platform_network_admins       = "Platform-Network-Admins"
    platform_mgmt_admins          = "Platform-Management-Admins"
    platform_mgmt_arc_admins      = "Platform-Management-ArcAdmins"
    platform_mgmt_devcenter_admins = "Platform-Management-DevCenterAdmins"
  }
}

resource "azuread_group" "platform" {
  for_each                = local.groups
  display_name            = each.value
  description             = "Platform persona group: ${each.value}"
  security_enabled        = true
  prevent_duplicate_names = true
}


# 2) ROLE DEFINITIONS PER MG SCOPE

locals {
  # mg-platform (root of platform layer)
  rbac_platform = [
    { group = "platform_owners", role = "Owner", scope = var.mg_platform_id }
  ]

  # mg-platform-identity
  rbac_identity = [
    { group = "platform_identity_admins", role = "User Access Administrator", scope = var.mg_identity_id },
    { group = "platform_identity_admins", role = "Reader",                    scope = var.mg_identity_id },
    { group = "platform_identity_secops", role = "Security Reader",           scope = var.mg_identity_id }
  ]

  # mg-platform-connectivity
  rbac_connectivity = [
    { group = "platform_network_admins", role = "Network Contributor",         scope = var.mg_connectivity_id },
    { group = "platform_network_admins", role = "Private DNS Zone Contributor", scope = var.mg_connectivity_id }
  ]

  # mg-platform-management
  rbac_management = [
    { group = "platform_mgmt_admins",     role = "Contributor",                                   scope = var.mg_management_id },
    { group = "platform_mgmt_arc_admins", role = "Azure Connected Machine Resource Administrator", scope = var.mg_management_id }
  ]

  rbac_all = concat(
    local.rbac_platform,
    local.rbac_identity,
    local.rbac_connectivity,
    local.rbac_management
  )
}


# 3) ASSIGN RBAC AT PLATFORM MG SCOPES

resource "azurerm_role_assignment" "platform" {
  for_each = {
    for idx, item in local.rbac_all : idx => item
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_group.platform[each.value.group].object_id
}