module "landing_zone" {
  source = "../../../../../patterns/oci/authenticated_serverless_api"

  providers = {
    oci      = oci
    oci.home = oci.home
  }

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    tenancy_ocid        = var.tenancy_ocid
    compartment_ocid    = var.compartment_ocid
    workload_region     = var.workload_region
    iam_home_region     = var.iam_home_region
    ocir_user_name      = var.ocir_user_name
    ocir_user_password  = var.ocir_user_password
    jwt_token           = var.jwt_token
    functions_base_path = "${path.module}/functions"
  }
}
