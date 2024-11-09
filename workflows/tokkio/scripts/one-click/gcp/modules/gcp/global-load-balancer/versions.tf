
terraform {
  #experiments = [module_variable_optional_attrs]
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "= 4.44.1"
#     }
#   }
#   required_version = "= 1.2.4"
# }
