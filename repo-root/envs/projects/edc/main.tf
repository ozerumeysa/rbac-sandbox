# envs/projects/eur/main.tf

# 1) Look up ISD MG by Group ID (name)
data "azurerm_management_group" "isd" {
  name = "mg-landingzone-ISD"
}

# 2) Deploy a project (change only project_code)
module "project" {
  source       = "../../../modules/project"
  project_code = "edc"  # <-- change this for each new project
  parent_mg_id = data.azurerm_management_group.isd.id
}