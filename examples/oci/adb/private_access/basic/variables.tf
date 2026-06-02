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

variable "adb_admin_password" {
  type      = string
  sensitive = true
}

variable "admin_ssh_public_key" {
  type = string
}
