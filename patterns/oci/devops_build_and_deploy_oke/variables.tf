variable "payload_file" {
  description = "Absolute or module-relative path to the landing zone YAML payload."
  type        = string
}

variable "payload_template_vars" {
  description = "Variables injected into the YAML payload through templatefile before yamldecode."
  type        = map(any)
  default     = {}
}

variable "ocir_user_password" {
  description = "OCI auth token used by the Helm packaging stage to log in to OCIR."
  type        = string
  sensitive   = true
}
