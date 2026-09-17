module "landing_zone" {
  source = "../../../../patterns/azure/aks_private_acr"

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    subscription_id     = var.subscription_id
    tenant_id           = var.tenant_id
    ssh_authorized_keys = [var.admin_ssh_public_key]
  }
}
