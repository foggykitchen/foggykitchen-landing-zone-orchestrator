module "landing_zone" {
  source = "../../../../../patterns/azure/multiregion_compute_failover"

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    subscription_id      = var.subscription_id
    tenant_id            = var.tenant_id
    admin_ssh_public_key = var.admin_ssh_public_key
  }
}
