# modules/platform/pim.tf (JIT via PIM)
###########################################

resource "time_static" "pim_start" {}

variable "pim_approver_group_object_id" {
  type        = string
  description = "Approver group object ID for PIM activations (defaults to Platform-Owners)"
  default     = null
}

locals {
  approver_oid        = coalesce(var.pim_approver_group_object_id, azuread_group.platform["platform_owners"].object_id)
  activation_duration = "PT4H"  # active session duration
  eligible_hours      = 720     # 30 days; adjust as you like
}

############### ROLE LOOKUPS ###############
data "azurerm_role_definition" "owner_platform" {
  name  = "Owner"
  scope = azurerm_management_group.platform.id
}
data "azurerm_role_definition" "uaa_identity" {
  name  = "User Access Administrator"
  scope = azurerm_management_group.identity.id
}
data "azurerm_role_definition" "network_contrib" {
  name  = "Network Contributor"
  scope = azurerm_management_group.connectivity.id
}
data "azurerm_role_definition" "pdns_contrib" {
  name  = "Private DNS Zone Contributor"
  scope = azurerm_management_group.connectivity.id
}
data "azurerm_role_definition" "mgmt_contributor" {
  name  = "Contributor"
  scope = azurerm_management_group.management.id
}

############# JIT ASSIGNMENTS #############
# mg-platform → Platform-Owners → Owner (JIT)
resource "azurerm_role_management_policy" "platform_owner_policy" {
  scope              = azurerm_management_group.platform.id
  role_definition_id = data.azurerm_role_definition.owner_platform.id
  eligible_assignment_rules { expiration_required = false }
  activation_rules {
    maximum_duration = local.activation_duration
    require_approval = true
    approval_stage { primary_approver { type = "Group", object_id = local.approver_oid } }
  }
}
resource "azurerm_pim_eligible_role_assignment" "platform_owner_eligible" {
  scope              = azurerm_management_group.platform.id
  role_definition_id = data.azurerm_role_definition.owner_platform.id
  principal_id       = azuread_group.platform["platform_owners"].object_id
  schedule {
    start_date_time = time_static.pim_start.rfc3339
    expiration { duration_hours = local.eligible_hours }
  }
}

# mg-platform-identity → Platform-Identity-Admins → UAA + Reader (JIT)
resource "azurerm_role_management_policy" "identity_uaa_policy" {
  scope              = azurerm_management_group.identity.id
  role_definition_id = data.azurerm_role_definition.uaa_identity.id
  eligible_assignment_rules { expiration_required = false }
  activation_rules {
    maximum_duration = local.activation_duration
    require_approval = true
    approval_stage { primary_approver { type = "Group", object_id = local.approver_oid } }
  }
}
resource "azurerm_pim_eligible_role_assignment" "identity_uaa_eligible" {
  scope              = azurerm_management_group.identity.id
  role_definition_id = data.azurerm_role_definition.uaa_identity.id
  principal_id       = azuread_group.platform["platform_identity_admins"].object_id
  schedule {
    start_date_time = time_static.pim_start.rfc3339
    expiration { duration_hours = local.eligible_hours }
  }
}

# mg-platform-connectivity → Platform-Network-Admins → Network + PDNS (JIT)
resource "azurerm_role_management_policy" "connectivity_network_policy" {
  scope              = azurerm_management_group.connectivity.id
  role_definition_id = data.azurerm_role_definition.network_contrib.id
  eligible_assignment_rules { expiration_required = false }
  activation_rules {
    maximum_duration = local.activation_duration
    require_approval = true
    approval_stage { primary_approver { type = "Group", object_id = local.approver_oid } }
  }
}
resource "azurerm_pim_eligible_role_assignment" "connectivity_network_eligible" {
  scope              = azurerm_management_group.connectivity.id
  role_definition_id = data.azurerm_role_definition.network_contrib.id
  principal_id       = azuread_group.platform["platform_network_admins"].object_id
  schedule {
    start_date_time = time_static.pim_start.rfc3339
    expiration { duration_hours = local.eligible_hours }
  }
}
resource "azurerm_pim_eligible_role_assignment" "connectivity_pdns_eligible" {
  scope              = azurerm_management_group.connectivity.id
  role_definition_id = data.azurerm_role_definition.pdns_contrib.id
  principal_id       = azuread_group.platform["platform_network_admins"].object_id
  schedule {
    start_date_time = time_static.pim_start.rfc3339
    expiration { duration_hours = local.eligible_hours }
  }
}

# mg-platform-management → Platform-Management-Admins → Contributor (JIT)
resource "azurerm_role_management_policy" "mgmt_contrib_policy" {
  scope              = azurerm_management_group.management.id
  role_definition_id = data.azurerm_role_definition.mgmt_contributor.id
  eligible_assignment_rules { expiration_required = false }
  activation_rules {
    maximum_duration = local.activation_duration
    require_approval = true
    approval_stage { primary_approver { type = "Group", object_id = local.approver_oid } }
  }
}
resource "azurerm_pim_eligible_role_assignment" "mgmt_contrib_eligible" {
  scope              = azurerm_management_group.management.id
  role_definition_id = data.azurerm_role_definition.mgmt_contributor.id
  principal_id       = azuread_group.platform["platform_mgmt_admins"].object_id
  schedule {
    start_date_time = time_static.pim_start.rfc3339
    expiration { duration_hours = local.eligible_hours }
  }
}
