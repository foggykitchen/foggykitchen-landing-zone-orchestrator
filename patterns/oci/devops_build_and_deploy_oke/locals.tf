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

  vcn_cidr                = try(local.architecture.network.vcn_cidr, "10.40.0.0/16")
  api_endpoint_cidr       = try(local.architecture.network.api_endpoint_subnet_cidr, "10.40.10.0/28")
  lb_cidr                 = try(local.architecture.network.lb_subnet_cidr, "10.40.20.0/24")
  nodes_cidr              = try(local.architecture.network.nodes_subnet_cidr, "10.40.30.0/24")
  project_name            = local.devops.project.name
  project_description     = try(local.devops.project.description, null)
  notification_enabled    = try(local.devops.project.enable_notifications, false)
  logging_enabled         = try(local.devops.project.enable_logging, false)
  devops_iam              = try(local.devops.iam, {})
  devops_operator_group   = try(local.devops_iam.operator_group_name, null)
  create_operator_policy  = local.devops_operator_group != null && trimspace(local.devops_operator_group) != ""
  dynamic_group_name      = try(local.devops_iam.dynamic_group_name, "${local.project_name}-dg")
  github_secret_comp_ocid = try(local.devops.github.pat_secret_compartment_ocid, local.compartment_ocid)

  app_connection_key        = "github"
  app_repository_key        = "app"
  helm_repository_key       = "helm"
  ocir_artifact_key         = "image"
  helm_chart_artifact_key   = "helm_chart"
  helm_values_artifact_key  = "helm_values"
  deploy_environment_key    = "oke"
  build_pipeline_key        = "app"
  deploy_pipeline_key       = "oke"
  app_branch                = try(local.devops.github.app_branch, "master")
  helm_branch               = try(local.devops.github.helm_branch, "main")
  image_repository_name     = local.devops.registry.image_repository_name
  helm_repository_name      = local.devops.registry.helm_repository_name
  helm_chart_name           = local.devops.helm.chart_name
  helm_chart_version_prefix = try(local.devops.helm.chart_version_prefix, "0.1.0")

  devops_dynamic_group_matching_rule = "Any {ALL {resource.type = 'devopsdeploypipeline', resource.compartment.id = '${local.compartment_ocid}'}, ALL {resource.type = 'devopsbuildpipeline', resource.compartment.id = '${local.compartment_ocid}'}, ALL {resource.type = 'devopsrepository', resource.compartment.id = '${local.compartment_ocid}'}, ALL {resource.type = 'devopsconnection', resource.compartment.id = '${local.compartment_ocid}'}}"

  values_yaml = templatefile("${path.module}/values.yaml.tftpl", {
    image_repository = module.ocir_image.image_prefix
    image_tag        = "${local.helm_chart_version_prefix}-$${BUILDRUN_HASH}"
    release_name     = local.helm_chart_name
  })
}
