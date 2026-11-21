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
variable "basedb_admin_password" {
  description = "Supply via TF_VAR_basedb_admin_password, not YAML or tfvars. OCI also checks complexity."
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(var.basedb_admin_password) >= 12 && length(var.basedb_admin_password) <= 30
    error_message = "basedb_admin_password must contain 12–30 characters."
  }
}
variable "database_version" {
  description = "Required regional database version; 23.26.4.0.0 is an example, not a regional availability guarantee."
  type        = string
  nullable    = false
  validation {
    condition     = length(trimspace(var.database_version)) > 0
    error_message = "database_version must not be empty."
  }
}
variable "operator_client_cidr" {
  description = "Trusted operator public IPv4 CIDR; supply via TF_VAR_operator_client_cidr. Prefer /32."
  type        = string
  nullable    = false
  validation {
    condition     = try(can(cidrnetmask(var.operator_client_cidr)) && tonumber(split("/", var.operator_client_cidr)[1]) > 0, false)
    error_message = "operator_client_cidr must be a valid IPv4 CIDR with a nonzero prefix; 0.0.0.0/0 is forbidden."
  }
}
variable "admin_ssh_public_key" {
  description = "Existing OpenSSH public key, or empty to generate an RSA lab key stored in state."
  type        = string
  default     = ""
  nullable    = false
}
