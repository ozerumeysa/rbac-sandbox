
# Variables

variable "parent_mg_id" {
  description = "Resource ID of the parent Management Group"
  type        = string
}

module "platform" {
  source        = "../../modules/platform"
  parent_mg_id  = var.parent_mg_id



  # Optional: override default MG names if you want different ones
  # mg_names = {
  #   platform     = "mg-platform"
  #   identity     = "mg-platform-identity"
  #   connectivity = "mg-platform-connectivity"
  #   management   = "mg-platform-management"
  # }
}