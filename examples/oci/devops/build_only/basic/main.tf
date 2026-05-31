module "landing_zone" {
  source = "../../../../../patterns/oci/devops_build_only"

  providers = {
    oci      = oci
    oci.home = oci.home
  }

  payload_file = "${path.module}/landing-zone.yaml"
  payload_template_vars = {
    tenancy_ocid                       = var.tenancy_ocid
    compartment_ocid                   = var.compartment_ocid
    workload_region                    = var.region
    iam_home_region                    = coalesce(var.iam_home_region, var.region)
    github_pat_secret_ocid             = var.github_pat_secret_ocid
    github_pat_secret_compartment_ocid = coalesce(var.github_pat_secret_compartment_ocid, var.compartment_ocid)
  }
}
