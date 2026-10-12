variable "payload_file" {
  description = "Path to the YAML payload file."
  type        = string
}

variable "payload_template_vars" {
  description = "Variables passed into templatefile before YAML decoding."
  type        = any
  default     = {}
  sensitive   = true
}
