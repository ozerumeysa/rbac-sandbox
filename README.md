# rbac-sandbox
RBAC redesign

#####envs/platform############# & envs/landingzone######
terraform init -upgrade

terraform plan -var='parent_mg_id=/providers/Microsoft.Management/managementGroups/d16693dc-99c6-428e-b8fd-3a70c9e85xxx'

terraform apply -var='parent_mg_id=/providers/Microsoft.Management/managementGroups/d16693dc-99c6-428e-b8fd-3a70c9e85xxx'


#####envs/isd#############
terraform init -upgrade


terraform plan -var='landingzone_mg_id=/providers/Microsoft.Management/managementGroups/mg-landingzone'


terraform apply -var='landingzone_mg_id=/providers/Microsoft.Management/managementGroups/mg-landingzone'

#####envs/project#############


terraform init 


terraform plan


terraform apply

