module "landing_zone" {
  source = "../../../../../patterns/oci/devops_build_and_deploy_oke"

  providers = {
    oci      = oci
    oci.home = oci.home
  }

  payload_file       = "${path.module}/landing-zone.yaml"
  ocir_user_password = var.ocir_user_password
  payload_template_vars = {
    tenancy_ocid                       = var.tenancy_ocid
    compartment_ocid                   = var.compartment_ocid
    workload_region                    = var.region
    iam_home_region                    = coalesce(var.iam_home_region, var.region)
    github_pat_secret_ocid             = var.github_pat_secret_ocid
    github_pat_secret_compartment_ocid = coalesce(var.github_pat_secret_compartment_ocid, var.compartment_ocid)
    ocir_user_name                     = var.ocir_user_name
  }
}
