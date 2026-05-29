locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  devops       = local.config.devops

  tenancy_ocid     = local.cloud.tenancy_ocid
  compartment_ocid = local.cloud.compartment_ocid
  iam_home_region  = local.cloud.home_region
  region           = try(local.cloud.workload_region, local.cloud.home_region)
  defined_tags     = try(local.landing_zone.defined_tags, {})
  freeform_tags    = try(local.landing_zone.freeform_tags, {})

  project_name        = local.devops.project.name
  project_description = try(local.devops.project.description, null)

  notification_enabled = try(local.devops.project.enable_notifications, false)
  logging_enabled      = try(local.devops.project.enable_logging, false)

  devops_iam                         = try(local.devops.iam, {})
  github_pat_secret_compartment_ocid = try(local.devops.github.pat_secret_compartment_ocid, local.compartment_ocid)

  devops_dynamic_group_name          = try(local.devops_iam.dynamic_group_name, "${local.project_name}-dg")
  devops_operator_group_name         = try(local.devops_iam.operator_group_name, null)
  create_operator_group_policy       = local.devops_operator_group_name != null && trimspace(local.devops_operator_group_name) != ""
  devops_dynamic_group_matching_rule = "Any {ALL {resource.type = 'devopsdeploypipeline', resource.compartment.id = '${local.compartment_ocid}'}, ALL {resource.type = 'devopsbuildpipeline', resource.compartment.id = '${local.compartment_ocid}'}, ALL {resource.type = 'devopsrepository', resource.compartment.id = '${local.compartment_ocid}'}, ALL {resource.type = 'devopsconnection', resource.compartment.id = '${local.compartment_ocid}'}}"

  github_connection_key = "github"
  github_repository_key = "app"
  ocir_artifact_key     = "app_image"
  build_pipeline_key    = "app"

  github_branch = try(local.devops.github.branch, "main")
}
