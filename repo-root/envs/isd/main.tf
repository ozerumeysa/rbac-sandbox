variable "landingzone_mg_id" {
  description = "Resource ID of mg-landingzone (parent scope for ISD)."
  type        = string
}

module "isd" {
  source           = "../../modules/isd"
  parent_mg_id     = var.landingzone_mg_id
  isd_mg_name      = "mg-landingzone-ISD"   # keep default; change if you need
}
