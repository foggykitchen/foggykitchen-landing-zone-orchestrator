module "landing_zone" {
  source = "../../../../../patterns/oci/multiregion_compute_failover"

  providers = {
    oci         = oci
    oci.home    = oci.home
    oci.standby = oci.standby
  }

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    tenancy_ocid         = var.tenancy_ocid
    compartment_ocid     = var.compartment_ocid
    iam_home_region      = var.iam_home_region
    primary_region       = var.primary_region
    standby_region       = var.standby_region
    admin_ssh_public_key = var.admin_ssh_public_key
  }
}
