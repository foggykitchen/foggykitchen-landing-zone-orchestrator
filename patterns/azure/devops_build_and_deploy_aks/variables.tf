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

variable "admin_ssh_public_key" {
  description = "Optional public key supplied separately from the YAML template, allowing TLS-generated keys without making the entire payload unknown during plan. Null uses workload.jump.ssh_authorized_keys."
  type        = string
  default     = null
  sensitive   = true
}
