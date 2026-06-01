variable "payload_file" {
  description = "Path to the landing-zone YAML payload file."
  type        = string
}

variable "payload_template_vars" {
  description = "Template variables injected into the landing-zone YAML payload."
  type        = map(any)
  default     = {}
}
