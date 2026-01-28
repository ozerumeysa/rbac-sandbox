terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

# 0. VARIABLES

variable "project_code" {
  description = "Short code for project, e.g. EUROM"
  type        = string
}

variable "parent_mg_id" {
  description = "Management Group ID under which the project MG will be created"
  type        = string
}

# 1. PROJECT MANAGEMENT GROUP

resource "azurerm_management_group" "project" {
  name                       = "mg-project-${var.project_code}"
  display_name               = "mg-project-${var.project_code}"
  parent_management_group_id = var.parent_mg_id
}


# 2. SECURITY GROUP CREATION

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


# 3. ROLE MATRIX FOR PROJECT PERSONAS

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

  # Flatten matrix → list of objects { persona, role }
  rbac_flat = flatten([
    for persona, roles in local.persona_roles : [
      for role in roles : {
        persona = persona
        role    = role
      }
    ]
  ])
}


# 4. ASSIGN RBAC AT PROJECT MG SCOPE

resource "azurerm_role_assignment" "persona_rbac" {
  for_each = {
    for idx, item in local.rbac_flat : idx => item
  }

  scope                = azurerm_management_group.project.id
  role_definition_name = each.value.role
  principal_id         = azuread_group.persona[each.value.persona].object_id
}


# 5. OUTPUTS

output "project_mg_id" {
  value = azurerm_management_group.project.id
}

output "persona_group_ids" {
  value = {
    for k, g in azuread_group.persona :
    k => g.object_id
  }
}