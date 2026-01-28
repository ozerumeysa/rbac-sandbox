terraform {
  required_version = ">= 1.6.0"
}

# Load shared providers (keeps code DRY and portable)
# You can symlink or copy from ../global/providers.tf if needed
# Or simply run from repo-root so Terraform loads it automatically.

variable "parent_mg_name" {
  description = "Name of the parent management group (e.g., Intermediate Root MG name)"
  type        = string
}

module "platform" {
  source         = "../../modules/platform"
  parent_mg_name = var.parent_mg_name

  # Optional: override names
  # mg_names = {
  #   platform     = "mg-platform"
  #   identity     = "mg-platform-identity"
  #   connectivity = "mg-platform-connectivity"
  #   management   = "mg-platform-management"
  # }
}