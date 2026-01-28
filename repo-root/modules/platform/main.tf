terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}


# Inputs

variable "parent_mg_id" {
  description = "Full resource ID of the parent Management Group."
  type        = string
}

variable "mg_names" {
  description = "Names for the Platform management groups"
  type = object({
    platform     = string
    identity     = string
    connectivity = string
    management   = string
  })
  default = {
    platform     = "mg-platform"
    identity     = "mg-platform-identity"
    connectivity = "mg-platform-connectivity"
    management   = "mg-platform-management"
  }
}


# Create Platform MG hierarchy

resource "azurerm_management_group" "platform" {
  name                       = var.mg_names.platform
  display_name               = var.mg_names.platform
  parent_management_group_id = var.parent_mg_id
}
# Creating/nesting management groups is done with azurerm_management_group. [2](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)

resource "azurerm_management_group" "identity" {
  name                       = var.mg_names.identity
  display_name               = var.mg_names.identity
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "connectivity" {
  name                       = var.mg_names.connectivity
  display_name               = var.mg_names.connectivity
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "management" {
  name                       = var.mg_names.management
  display_name               = var.mg_names.management
  parent_management_group_id = azurerm_management_group.platform.id
}


# Entra (AAD) security groups for Platform personas

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
# Entra security groups are created via azuread_group. [3](https://shisho.dev/dojo/providers/azurerm/Management/azurerm-management-group/)


# RBAC matrix (simple & clear)

locals {
  # mg-platform
  rbac_platform = [
    { group = "platform_owners",     role = "Owner",                    scope = azurerm_management_group.platform.id }
  ]

  # mg-platform-identity
  rbac_identity = [
    { group = "platform_identity_admins", role = "User Access Administrator", scope = azurerm_management_group.identity.id },
    { group = "platform_identity_admins", role = "Reader",                     scope = azurerm_management_group.identity.id },
    { group = "platform_identity_secops", role = "Security Reader",            scope = azurerm_management_group.identity.id }
  ]

  # mg-platform-connectivity
  rbac_connectivity = [
    { group = "platform_network_admins",  role = "Network Contributor",          scope = azurerm_management_group.connectivity.id },
    { group = "platform_network_admins",  role = "Private DNS Zone Contributor", scope = azurerm_management_group.connectivity.id }
  ]

  # mg-platform-management
  rbac_management = [
    { group = "platform_mgmt_admins",     role = "Contributor",                                   scope = azurerm_management_group.management.id },
    { group = "platform_mgmt_arc_admins", role = "Azure Connected Machine Resource Administrator", scope = azurerm_management_group.management.id }
    # DevCenter Admins typically assigned later at Dev Center/Project scope
  ]

  rbac_all = concat(local.rbac_platform, local.rbac_identity, local.rbac_connectivity, local.rbac_management)
}

resource "azurerm_role_assignment" "platform" {
  for_each = { for idx, item in local.rbac_all : idx => item }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_group.platform[each.value.group].object_id
}
# RBAC assignments are done with azurerm_role_assignment using scope, role_definition_name, principal_id. [4](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/landing-zone-governance)


# Outputs

output "mg_platform_id"      { value = azurerm_management_group.platform.id }
output "mg_identity_id"      { value = azurerm_management_group.identity.id }
output "mg_connectivity_id"  { value = azurerm_management_group.connectivity.id }
output "mg_management_id"    { value = azurerm_management_group.management.id }