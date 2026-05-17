module "landing_zone" {
  source = "../../../../../patterns/azure/firewall_transit"

  payload_file         = "${path.module}/landing-zone.yaml"
  admin_ssh_public_key = var.admin_ssh_public_key
}
