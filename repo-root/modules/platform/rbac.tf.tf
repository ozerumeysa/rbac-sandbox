
# modules/platform/rbac.tf (JEA only)
########################################

locals {
  rbac_jea = [
    // mg-platform-identity → Platform-Identity-SecurityOps → Security Reader (JEA)
    {
      group = "platform_identity_secops"
      role  = "Security Reader"
      scope = azurerm_management_group.identity.id
    },

    // mg-platform-management → Platform-Management-ArcAdmins → Arc Admin (JEA)
    {
      group = "platform_mgmt_arc_admins"
      role  = "Azure Connected Machine Resource Administrator"
      scope = azurerm_management_group.management.id
    },

    // mg-platform-management → Platform-Management-DevCenterAdmins → DevCenter Admin (JEA)
    {
      group = "platform_mgmt_devcenter_admins"
      role  = "DevCenter Project Admin"
      scope = azurerm_management_group.management.id
    }
  ]
}

resource "azurerm_role_assignment" "jea_assignments" {
  for_each             = { for idx, item in local.rbac_jea : idx => item }
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azuread_group.platform[each.value.group].object_id
}