terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm" }
    azuread = { source = "hashicorp/azuread" }
  }
}


# Inputs

variable "parent_mg_id" {
  description = "Resource ID of the parent MG (ISD)."
  type        = string
}

variable "project_code" {
  description = "Short code for project (e.g., EUR)."
  type        = string
}


# 1. Create project MG under ISD

resource "azurerm_management_group" "project" {
  name                       = "mg-project-${var.project_code}"
  display_name               = "mg-project-${var.project_code}"
  parent_management_group_id = var.parent_mg_id
}
# MG creation/nesting is done with azurerm_management_group. [1](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)


# 2. Create Entra security groups

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
  description             = "Persona group ${each.key} for project ${var.project_code}"
  security_enabled        = true
  prevent_duplicate_names = true
}
# Entra security groups are created via azuread_group. [2](https://shisho.dev/dojo/providers/azurerm/Management/azurerm-management-group/)


# 3. Define RBAC roles per persona

locals {
  persona_roles = {

    # Application team (broad contributor + VM login + Dev Box user)
    app = [
      "Contributor",
      "Virtual Machine Administrator Login",
      "Virtual Machine User Login",
      "DevCenter Dev Box User"
    ]

    # Read-only visibility
    appreader = [
      "Reader"
    ]

    # DataOps (storage + KV + privileged file read)
    dataops = [
      "Storage Blob Data Owner",
      "Key Vault Contributor",
      "Storage File Data Privileged Reader"
    ]

    # DataOps Read-only set
    dataopsreader = [
      "Storage Blob Data Reader",
      "Storage File Data SMB Share Reader",
      "Key Vault Reader",
      "Reader"
    ]

    # DevOps / automation (registry + managed identity + k8s agent)
    devopsauto = [
      "AcrPull",
      "AcrPush",
      "Defender Kubernetes Agent Operator",
      "Kubernetes Agent Subscription Level Operator",
      "Managed Identity Operator",
      "Managed Identity Federated Identity Credential Contributor"
    ]
  }

  # Flatten to [{ persona, role }, ...]
  rbac_flat = flatten([
    for persona, roles in local.persona_roles : [
      for role in roles : {
        persona = persona
        role    = role
      }
    ]
  ])
}


# 4. Assign RBAC at project MG

resource "azurerm_role_assignment" "persona_rbac" {
  for_each = { for idx, item in local.rbac_flat : idx => item }

  scope                = azurerm_management_group.project.id
  role_definition_name = each.value.role
  principal_id         = azuread_group.persona[each.value.persona].object_id
}
# RBAC bindings are applied via azurerm_role_assignment at MG scope. [3](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/landing-zone-governance)


# Outputs

output "project_mg_id" {
  value = azurerm_management_group.project.id
}

output "persona_group_ids" {
  value = { for k, g in azuread_group.persona : k => g.object_id }
}