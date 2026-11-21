locals {
  effective_admin_ssh_public_key = trimspace(var.admin_ssh_public_key) != "" ? trimspace(var.admin_ssh_public_key) : tls_private_key.generated[0].public_key_openssh
}
resource "tls_private_key" "generated" {
  count     = trimspace(var.admin_ssh_public_key) == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}
module "landing_zone" {
  providers    = { oci = oci, time = time }
  source       = "../../../../../../patterns/oci/basedb_private_access"
  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    tenancy_ocid         = var.tenancy_ocid
    compartment_ocid     = var.compartment_ocid
    workload_region      = var.workload_region
    database_version     = var.database_version
    operator_client_cidr = var.operator_client_cidr
  }
  basedb_admin_password = var.basedb_admin_password
  admin_ssh_public_key  = local.effective_admin_ssh_public_key
}
