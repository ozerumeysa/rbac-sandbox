terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}


# Inputs

variable "parent_mg_id" {
  description = "Resource ID of mg-landingzone."
  type        = string
}

variable "isd_mg_name" {
  description = "Name for the ISD management group."
  type        = string
  default     = "mg-landingzone-ISD"
}


# Create ISD MG under mg-landingzone

resource "azurerm_management_group" "isd" {
  name                       = var.isd_mg_name
  display_name               = var.isd_mg_name
  parent_management_group_id = var.parent_mg_id
}
# Management groups are created/nested via azurerm_management_group. [1](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)


# Entra (AAD) security groups

locals {
  isd_groups = {
    app_contrib = "ISD-App-Contributors"
    app_reader  = "ISD-App-Reader"
    secops      = "ISD-SecurityOps"
    finance     = "ISD-Finance-Governance"
  }
}

resource "azuread_group" "isd" {
  for_each                = local.isd_groups
  display_name            = each.value
  security_enabled        = true
  prevent_duplicate_names = true
}
# Entra security groups are created via azuread_group. [2](https://shisho.dev/dojo/providers/azurerm/Management/azurerm-management-group/)


# RBAC matrix

locals {
  isd_rbac = [
    # ISD App
    { group = "app_contrib", role = "Contributor" },
    { group = "app_reader",  role = "Reader" },

    # ISD Finance
    { group = "finance",     role = "Cost Management Contributor" },
    { group = "finance",     role = "Billing Reader" },

    # ISD SecurityOps (Defender + admin)
    { group = "secops",      role = "User Access Administrator" },
    { group = "secops",      role = "Key Vault Administrator" },
    { group = "secops",      role = "Security Reader" },
    { group = "secops",      role = "Defender CSPM Storage Scanner Operator" },
    { group = "secops",      role = "Defender Kubernetes API Access" },
    { group = "secops",      role = "Defender Agentless VM Scan" },
    { group = "secops",      role = "Defender for Storage Scanner Operator" },
    { group = "secops",      role = "Defender Sensitive Data Discovery" },
    { group = "secops",      role = "Defender for Storage Data Scanner" }
  ]
}

resource "azurerm_role_assignment" "isd_assign" {
  for_each = { for idx, item in local.isd_rbac : idx => item }

  scope                = azurerm_management_group.isd.id
  role_definition_name = each.value.role
  principal_id         = azuread_group.isd[each.value.group].object_id
}
# RBAC assignment is done via azurerm_role_assignment using scope, role_definition_name, principal_id. [3](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/landing-zone-governance)


# Outputs

output "isd_mg_id" { value = azurerm_management_group.isd.id }

output "group_ids" {
  value = { for k, g in azuread_group.isd : k => g.object_id }
}