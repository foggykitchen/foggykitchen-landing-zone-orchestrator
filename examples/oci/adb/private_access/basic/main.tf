module "landing_zone" {
  source = "../../../../../patterns/oci/adb_private_access"

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    tenancy_ocid         = var.tenancy_ocid
    compartment_ocid     = var.compartment_ocid
    workload_region      = var.workload_region
    adb_admin_password   = var.adb_admin_password
    admin_ssh_public_key = var.admin_ssh_public_key
  }
}
