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

variable "workload_region" {
  type = string
}

variable "iam_home_region" {
  type = string
}

variable "ocir_user_name" {
  type = string
}

variable "ocir_user_password" {
  type      = string
  sensitive = true
}

variable "jwt_token" {
  type      = string
  sensitive = true
}
