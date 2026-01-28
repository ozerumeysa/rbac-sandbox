# envs/projects/edc/main.tf

variable "parent_mg_id" {
  description = "Resource ID of the parent MG (ISD), e.g. /providers/Microsoft.Management/managementGroups/mg-landingzone-ISD"
  type        = string
}

variable "project_code" {
  description = "Short code for the project (used in names), e.g., EUROM"
  type        = string
  default     = "edc"
}

module "project" {
  source        = "../../../modules/project"
  parent_mg_id  = var.parent_mg_id
  project_code  = var.project_code
}