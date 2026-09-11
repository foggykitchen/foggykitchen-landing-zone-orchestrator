module "landing_zone" {
  source = "../../../../../../patterns/azure/sql_private_access"

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    subscription_id     = var.subscription_id
    tenant_id           = var.tenant_id
    sql_admin_password  = var.sql_admin_password
    ssh_authorized_keys = [var.admin_ssh_public_key]
  }
}
