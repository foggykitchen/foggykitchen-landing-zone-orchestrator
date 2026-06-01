module "landing_zone" {
  source = "../../../../../patterns/oci/event_driven_data_pipeline"

  providers = {
    oci      = oci
    oci.home = oci.home
  }

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    tenancy_ocid          = var.tenancy_ocid
    compartment_ocid      = var.compartment_ocid
    workload_region       = var.region
    iam_home_region       = coalesce(var.iam_home_region, var.region)
    ocir_user_name        = var.ocir_user_name
    ocir_user_password    = var.ocir_user_password
    adb_admin_password    = var.adb_admin_password
    adb_app_user_password = var.adb_app_user_password
    functions_base_path   = "${path.module}/functions"
  }
}
