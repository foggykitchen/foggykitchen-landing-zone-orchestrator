variable "subscription_id" {
  description = "Azure subscription ID used by the example provider and payload."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID used by the example provider and payload."
  type        = string
}

variable "admin_ssh_public_key" {
  description = "Optional SSH public key; leave empty to generate an RSA key pair with the TLS provider."
  type        = string
  default     = ""
  sensitive   = true
}

variable "organization_url" {
  description = "Azure DevOps organization URL; authenticate with AZDO_PERSONAL_ACCESS_TOKEN."
  type        = string
}

variable "subscription_name" {
  description = "Display name of the Azure subscription for the OIDC endpoint."
  type        = string
}

variable "build_agent_pool_name" {
  description = "Name of the self-hosted pool created for the Build agent on the jump VM."
  type        = string
  validation {
    condition     = length(trimspace(var.build_agent_pool_name)) > 0 && var.build_agent_pool_name != "Azure Pipelines"
    error_message = "Use a self-hosted pool with private ACR connectivity, not Microsoft-hosted Azure Pipelines."
  }
}
