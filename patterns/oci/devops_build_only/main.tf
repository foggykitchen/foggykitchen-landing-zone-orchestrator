module "policy" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-policy.git?ref=v0.1.0"

  providers = {
    oci = oci.home
  }

  tenancy_ocid = local.tenancy_ocid

  dynamic_group = {
    name          = local.devops_dynamic_group_name
    description   = "Dynamic group for OCI DevOps build-only pattern resources"
    matching_rule = local.devops_dynamic_group_matching_rule
  }

  policies = concat(
    [
      {
        name        = "${local.project_name}-devops-dg-policy"
        description = "Allow OCI DevOps build-only resources to access Vault, OCIR, DevOps, and optional notifications"
        statements = concat(
          [
            "Allow dynamic-group ${local.devops_dynamic_group_name} to read secret-family in compartment id ${local.github_pat_secret_compartment_ocid}",
            "Allow dynamic-group ${local.devops_dynamic_group_name} to manage repos in compartment id ${local.compartment_ocid}",
            "Allow dynamic-group ${local.devops_dynamic_group_name} to manage devops-family in compartment id ${local.compartment_ocid}"
          ],
          local.notification_enabled ? [
            "Allow dynamic-group ${local.devops_dynamic_group_name} to use ons-topics in compartment id ${local.compartment_ocid}"
          ] : []
        )
      }
    ],
    local.create_operator_group_policy ? [
      {
        name        = "${local.project_name}-devops-operators-policy"
        description = "Allow DevOps operators to validate and use external GitHub connections"
        statements = [
          "Allow group ${local.devops_operator_group_name} to use devops-connection in compartment id ${local.compartment_ocid}"
        ]
      }
    ] : []
  )

}

module "ocir" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-ocir.git?ref=v0.1.0"

  compartment_ocid = local.compartment_ocid
  repository_name  = local.devops.registry.repository_name
  region           = local.region
  defined_tags     = local.defined_tags
  freeform_tags    = local.freeform_tags
}

module "devops" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-devops.git?ref=v0.1.0"

  compartment_ocid           = local.compartment_ocid
  project_name               = local.project_name
  project_description        = local.project_description
  create_notification_topic  = local.notification_enabled
  notification_topic_name    = local.notification_enabled ? "${local.project_name}-topic" : null
  create_log_group           = local.logging_enabled
  create_project_service_log = local.logging_enabled
  log_group_name             = local.logging_enabled ? "${local.project_name}-logs" : null
  project_log_name           = local.logging_enabled ? "${local.project_name}-service-log" : null

  connections = {
    (local.github_connection_key) = {
      display_name = "${local.project_name}-github"
      access_token = local.devops.github.pat_secret_ocid
    }
  }

  repositories = {
    (local.github_repository_key) = {
      name           = local.devops.github.repository_name
      connection_key = local.github_connection_key
      repository_url = local.devops.github.repository_url
      branch         = local.github_branch
    }
  }

  deploy_artifacts = {
    (local.ocir_artifact_key) = {
      display_name               = module.ocir.repository_name
      argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
      deploy_artifact_type       = "DOCKER_IMAGE"
      source = {
        type           = "OCIR"
        image_uri      = "${module.ocir.image_prefix}:0.1.0-$${BUILDRUN_HASH}"
        image_digest   = " "
        repository_key = local.github_repository_key
      }
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}

module "devops_pipeline" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-devops-pipeline.git?ref=v0.1.2"

  project_id = module.devops.project_id

  build_pipelines = {
    (local.build_pipeline_key) = {
      display_name = local.devops.build_pipeline.name
      description  = try(local.devops.build_pipeline.description, null)
      parameters   = try(local.devops.build_pipeline.parameters, [])
      stages = [
        {
          key                                = "build"
          stage_type                         = "BUILD"
          display_name                       = try(local.devops.build_pipeline.build_stage.name, "build")
          description                        = try(local.devops.build_pipeline.build_stage.description, null)
          build_spec_file                    = try(local.devops.build_pipeline.build_stage.build_spec_file, "build_spec.yaml")
          image                              = try(local.devops.build_pipeline.build_stage.image, "OL7_X86_64_STANDARD_10")
          stage_execution_timeout_in_seconds = try(local.devops.build_pipeline.build_stage.timeout_in_seconds, 36000)
          build_sources = [
            {
              name           = local.devops.github.repository_name
              branch         = local.github_branch
              repository_id  = module.devops.repository_ids[local.github_repository_key]
              repository_url = local.devops.github.repository_url
            }
          ]
        },
        {
          key              = "deliver"
          stage_type       = "DELIVER_ARTIFACT"
          display_name     = try(local.devops.build_pipeline.deliver_stage.name, "deliver")
          description      = try(local.devops.build_pipeline.deliver_stage.description, null)
          predecessor_keys = ["build"]
          deliver_artifacts = [
            {
              artifact_id   = module.devops.deploy_artifact_ids[local.ocir_artifact_key]
              artifact_name = try(local.devops.build_pipeline.deliver_stage.artifact_name, "APPLICATION_DOCKER_IMAGE")
            }
          ]
        }
      ]
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}
