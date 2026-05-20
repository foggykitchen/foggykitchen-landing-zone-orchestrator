variable "admin_ssh_public_key" {
  description = "Optional SSH public key injected into created Linux VMs. Leave empty to generate a temporary key pair with the TLS provider."
  type        = string
  default     = ""
}

variable "provisioner_public_ip" {
  description = "Optional public IP/CIDR of the provisioning machine allowed to create Storage data-plane resources during apply."
  type        = string
  default     = ""
}
