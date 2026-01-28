terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}

# -------------------------
# Inputs
# -------------------------
variable "project_code" {
  description = "Short code for project (e.g., edc, dcc)"
  type        = string
}

variable "parent_mg_id" {
  description = "Resource ID of the parent management group (ISD)"
  type        = string
}

# -------------------------
# 1. Create project MG
# -------------------------
resource "azurerm_management_group" "project" {
  name                       = "mg-project-${var.project_code}"
  display_name               = "mg-project-${var.project_code}"
  parent_management_group_id = var.parent_mg_id
}

# -------------------------
# 2. Create security groups
# -------------------------
locals {
  personas = {
    app           = "${var.project_code}-App"
    appreader     = "${var.project_code}-AppReader"
    dataops       = "${var.project_code}-DataOps"
    dataopsreader = "${var.project_code}-DataOpsReader"
    devopsauto    = "${var.project_code}-DevOpsAuto"
  }
}

resource "azuread_group" "persona" {
  for_each                = local.personas
  display_name            = each.value
  security_enabled        = true
  description             = "Persona group ${each.key} for project ${var.project_code}"
  prevent_duplicate_names = true
}

# -------------------------
# 3. Define RBAC roles per persona
# -------------------------
locals {
  persona_roles = {
    app = [
      "Contributor",
      "Virtual Machine Administrator Login",
      "Virtual Machine User Login",
      "DevCenter Dev Box User"
    ]

    appreader = [
      "Reader"
    ]

    dataops = [
      "Storage Blob Data Owner",
      "Key Vault Contributor",
      "Storage File Data Privileged Reader"
    ]

    dataopsreader = [
      "Storage Blob Data Reader",
      "Storage File Data SMB Share Reader",
      "Key Vault Reader",
      "Reader"
    ]

    devopsauto = [
      "AcrPull",
      "AcrPush",
      "Defender Kubernetes Agent Operator",
      "Kubernetes Agent Subscription Level Operator",
      "Managed Identity Operator",
      "Managed Identity Federated Identity Credential Contributor"
    ]
  }

  # Expand into a flat list for for_each
  rbac_flat = flatten([
    for persona, roles in local.persona_roles : [
      for role in roles : {
        persona = persona
        role    = role
      }
    ]
  ])
}

# -------------------------
# 4. Assign RBAC at project MG
# -------------------------
resource "azurerm_role_assignment" "persona_rbac" {
  for_each = {
    for idx, item in local.rbac_flat :
    idx => item
  }

  scope                = azurerm_management_group.project.id
  role_definition_name = each.value.role
  principal_id         = azuread_group.persona[each.value.persona].object_id
}

# -------------------------
# Outputs
# -------------------------
output "project_mg_id" {
  value = azurerm_management_group.project.id
}

output "persona_group_ids" {
  value = { for k, g in azuread_group.persona : k => g.object_id }
}
