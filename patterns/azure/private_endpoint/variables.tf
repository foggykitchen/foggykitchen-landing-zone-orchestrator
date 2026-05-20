variable "payload_file" {
  description = "Absolute or module-relative path to the landing zone YAML payload."
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key injected into created Linux VMs."
  type        = string
}

variable "provisioner_public_ip" {
  description = "Optional public IP/CIDR of the provisioning machine allowed to create storage data-plane resources such as Azure File Shares."
  type        = string
  default     = ""
}
