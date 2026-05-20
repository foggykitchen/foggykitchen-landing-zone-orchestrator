locals {
  effective_admin_ssh_public_key = trimspace(var.admin_ssh_public_key) != "" ? trimspace(var.admin_ssh_public_key) : tls_private_key.generated[0].public_key_openssh
}

resource "tls_private_key" "generated" {
  count     = trimspace(var.admin_ssh_public_key) == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "landing_zone" {
  source = "../../../../../patterns/azure/private_endpoint"

  payload_file          = "${path.module}/landing-zone.yaml"
  admin_ssh_public_key  = local.effective_admin_ssh_public_key
  provisioner_public_ip = trimspace(var.provisioner_public_ip)
}
