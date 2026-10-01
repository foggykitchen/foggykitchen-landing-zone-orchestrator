module "landing_zone" {
  source = "../../../../../patterns/azure/event_driven_data_pipeline"

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    subscription_id           = var.subscription_id
    tenant_id                 = var.tenant_id
    location                  = var.location
    my_public_ip              = var.my_public_ip
    functions_base_path       = "${path.module}/functions"
    apim_publisher_name       = var.apim_publisher_name
    apim_publisher_email      = var.apim_publisher_email
    postgresql_admin_password = var.postgresql_admin_password
  }
}
