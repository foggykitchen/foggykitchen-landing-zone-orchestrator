variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}

variable "iam_home_region" {
  type    = string
  default = null
}

variable "github_pat_secret_ocid" {
  type = string
}

variable "github_pat_secret_compartment_ocid" {
  type    = string
  default = null
}

variable "ocir_user_name" {
  type = string
}

variable "ocir_user_password" {
  type      = string
  sensitive = true
}
