locals {
  effective_admin_ssh_public_key = trimspace(var.admin_ssh_public_key) != "" ? trimspace(var.admin_ssh_public_key) : tls_private_key.generated[0].public_key_openssh
}

resource "tls_private_key" "generated" {
  count     = trimspace(var.admin_ssh_public_key) == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "landing_zone" {
  source = "../../../../../patterns/oci/adb_private_access"

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    tenancy_ocid         = var.tenancy_ocid
    compartment_ocid     = var.compartment_ocid
    workload_region      = var.workload_region
    adb_admin_password   = var.adb_admin_password
    admin_ssh_public_key = local.effective_admin_ssh_public_key
  }
}
