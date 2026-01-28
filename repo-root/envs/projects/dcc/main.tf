# 1) Look up ISD MG by Group ID (name)
data "azurerm_management_group" "isd" {
  name = "mg-landingzone-ISD"
}

# 2) Deploy this project (change only project_code)
module "project_edc" {
  source       = "../../../modules/project"
  project_code = "dcc"  # <-- change this per new project
  parent_mg_id = data.azurerm_management_group.isd.id
}