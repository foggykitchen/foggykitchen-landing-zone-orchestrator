variable "payload_file" {
  description = "Path to the landing zone YAML template."
  type        = string
}
variable "payload_template_vars" {
  description = "Non-secret, plan-known variables for the YAML template. Password and SSH key use separate inputs."
  type        = map(string)
  default     = {}
}
variable "basedb_admin_password" {
  description = "Runtime SYS password; never rendered into YAML. Stored in provider state."
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(var.basedb_admin_password) >= 12 && length(var.basedb_admin_password) <= 30
    error_message = "basedb_admin_password must contain 12–30 characters."
  }
}
variable "admin_ssh_public_key" {
  description = "Runtime public key shared by the client, BaseDB and managed SSH session. May be unknown until apply."
  type        = string
  nullable    = false
}
