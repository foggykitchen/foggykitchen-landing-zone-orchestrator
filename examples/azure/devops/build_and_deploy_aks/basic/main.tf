locals {
  effective_admin_ssh_public_key = trimspace(var.admin_ssh_public_key) != "" ? trimspace(var.admin_ssh_public_key) : tls_private_key.generated[0].public_key_openssh
}

resource "tls_private_key" "generated" {
  count     = trimspace(var.admin_ssh_public_key) == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "landing_zone" {
  source = "../../../../../patterns/azure/devops_build_and_deploy_aks"

  admin_ssh_public_key = local.effective_admin_ssh_public_key
  payload_file         = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    organization_url      = var.organization_url
    subscription_name     = var.subscription_name
    build_agent_pool_name = var.build_agent_pool_name
    subscription_id       = var.subscription_id
    tenant_id             = var.tenant_id
  }
}
