# envs/landingzone/main.tf

variable "parent_mg_id" {
  description = "Resource ID of the parent MG (Tenant Root)."
  type        = string
}

module "landingzones" {
  source       = "../../modules/landingzone"
  parent_mg_id = var.parent_mg_id

  # Optional: change the mg name if you prefer
  # mg_name = "mg-landingzone"
}