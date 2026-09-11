module "landing_zone" {
  source = "../../../../../../patterns/azure/database_private_access"

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    subscription_id           = var.subscription_id
    tenant_id                 = var.tenant_id
    postgresql_admin_password = var.postgresql_admin_password
    ssh_authorized_keys       = [var.admin_ssh_public_key]
  }
}
