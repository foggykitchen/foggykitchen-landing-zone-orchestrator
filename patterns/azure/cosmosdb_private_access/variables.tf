variable "payload_file" {
  description = "Path to the YAML landing-zone payload."
  type        = string
}

variable "payload_template_vars" {
  description = "Variables passed to templatefile() when rendering the payload."
  type        = any
  default     = {}
  sensitive   = true
}
