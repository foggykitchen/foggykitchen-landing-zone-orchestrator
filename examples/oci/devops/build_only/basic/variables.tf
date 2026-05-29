variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID."
  type        = string
}

variable "fingerprint" {
  description = "OCI API signing key fingerprint."
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key."
  type        = string
}

variable "region" {
  description = "OCI workload region for DevOps, OCIR, logging, and notifications."
  type        = string
}

variable "iam_home_region" {
  description = "OCI home region used for IAM resources such as dynamic groups and policies. Defaults to region when null."
  type        = string
  default     = null
}

variable "compartment_ocid" {
  description = "OCI compartment OCID for the build-only pattern example."
  type        = string
}

variable "github_pat_secret_ocid" {
  description = "OCI Vault secret OCID containing the GitHub personal access token."
  type        = string
}

variable "github_pat_secret_compartment_ocid" {
  description = "OCI compartment OCID containing the Vault secret for the GitHub PAT. Defaults to compartment_ocid when null."
  type        = string
  default     = null
}

variable "availability_domain" {
  description = "Optional passthrough variable kept only to stay compatible with shared tfvars files."
  type        = string
  default     = null
}
