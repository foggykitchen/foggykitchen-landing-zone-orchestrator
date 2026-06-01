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
  description = "OCI workload region for the event-driven data pipeline."
  type        = string
}

variable "iam_home_region" {
  description = "OCI home region used for IAM resources such as policies and dynamic groups. Defaults to region when null."
  type        = string
  default     = null
}

variable "compartment_ocid" {
  description = "OCI compartment OCID for the event-driven data pipeline example."
  type        = string
}

variable "ocir_user_name" {
  description = "OCI Registry user name used for function image push."
  type        = string
}

variable "ocir_user_password" {
  description = "OCI Registry auth token used for function image push."
  type        = string
  sensitive   = true
}

variable "adb_admin_password" {
  description = "Administrator password for the Autonomous Database."
  type        = string
  sensitive   = true
}

variable "adb_app_user_password" {
  description = "Application user password used by the collector function."
  type        = string
  sensitive   = true
}

variable "availability_domain" {
  description = "Optional passthrough variable kept only to stay compatible with shared tfvars files."
  type        = string
  default     = null
}
