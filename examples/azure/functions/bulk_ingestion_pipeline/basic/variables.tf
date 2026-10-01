variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "location" {
  description = "Azure region for the bulk ingestion pipeline example."
  type        = string
  default     = "westeurope"
}

variable "my_public_ip" {
  description = "Public IP address of the OpenTofu runner allowed to reach the Function host Storage Account during updates."
  type        = string
}

variable "apim_publisher_name" {
  description = "Publisher name used by Azure API Management."
  type        = string
}

variable "apim_publisher_email" {
  description = "Publisher email used by Azure API Management."
  type        = string
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password used by the collector function."
  type        = string
  sensitive   = true
}
