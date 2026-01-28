# envs/landingzone/main.tf

variable "parent_mg_id" {
  description = "Resource ID of the parent Management Group (Tenant Root)."
  type        = string
}

# Optionally override mg name if you wish later
# variable "mg_name" {
#   type    = string
#   default = "mg-landingzone"
# }

module "landingzone" {
  source       = "../../modules/landingzone"
  parent_mg_id = var.parent_mg_id

  # If you ever want to pass a different name:
  # mg_name = var.mg_name
}