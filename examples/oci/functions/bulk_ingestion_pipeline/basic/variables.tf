variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "region" {
  type = string
}

variable "iam_home_region" {
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

variable "adb_admin_password" {
  type      = string
  sensitive = true
}

variable "adb_app_user_password" {
  type      = string
  sensitive = true
}
