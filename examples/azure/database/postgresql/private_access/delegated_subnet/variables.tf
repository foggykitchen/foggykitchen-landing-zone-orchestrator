variable "subscription_id" {
  description = "Azure subscription ID used by the example provider and payload."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID used by the example provider and payload."
  type        = string
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password injected into the payload."
  type        = string
  sensitive   = true
}

variable "admin_ssh_public_key" {
  description = "SSH public key injected into the validation host payload."
  type        = string
  sensitive   = true
}
