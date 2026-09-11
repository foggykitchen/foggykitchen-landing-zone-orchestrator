variable "payload_file" {
  description = "Path to the YAML payload file."
  type        = string
}

variable "payload_template_vars" {
  description = "Values injected into the YAML payload with templatefile."
  type        = any
  default     = {}
  sensitive   = true
}
