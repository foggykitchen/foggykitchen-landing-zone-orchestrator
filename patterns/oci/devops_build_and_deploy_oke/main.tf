module "policy" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-policy.git?ref=v0.1.0"

  providers = {
    oci = oci.home
  }

  tenancy_ocid = local.tenancy_ocid

  dynamic_group = {
    name          = local.dynamic_group_name
    description   = "Dynamic group for OCI DevOps build-and-deploy-oke pattern resources"
    matching_rule = local.devops_dynamic_group_matching_rule
  }

  policies = concat(
    [
      {
        name        = "${local.project_name}-devops-dg-policy"
        description = "Allow OCI DevOps build-and-deploy-oke resources to access Vault, DevOps, OKE, networking, and OCIR"
        statements = concat(
          [
            "Allow dynamic-group ${local.dynamic_group_name} to read secret-family in compartment id ${local.github_secret_comp_ocid}",
            "Allow dynamic-group ${local.dynamic_group_name} to manage all-resources in compartment id ${local.compartment_ocid}",
            "Allow dynamic-group ${local.dynamic_group_name} to use devops-family in compartment id ${local.compartment_ocid}",
            "Allow dynamic-group ${local.dynamic_group_name} to manage repos in compartment id ${local.compartment_ocid}",
            "Allow dynamic-group ${local.dynamic_group_name} to read repos in tenancy where ANY { request.operation = 'ReadDockerRepositoryMetadata', request.operation = 'ReadDockerRepositoryManifest', request.operation = 'PullDockerLayer' }",
            "Allow dynamic-group ${local.dynamic_group_name} to use subnets in compartment id ${local.compartment_ocid}",
            "Allow dynamic-group ${local.dynamic_group_name} to use vnics in compartment id ${local.compartment_ocid}",
            "Allow dynamic-group ${local.dynamic_group_name} to use network-security-groups in compartment id ${local.compartment_ocid}",
            "Allow dynamic-group ${local.dynamic_group_name} to use cabundles in compartment id ${local.compartment_ocid}"
          ],
          local.notification_enabled ? [
            "Allow dynamic-group ${local.dynamic_group_name} to use ons-topics in compartment id ${local.compartment_ocid}"
          ] : []
        )
      }
    ],
    local.create_operator_policy ? [
      {
        name        = "${local.project_name}-devops-operators-policy"
        description = "Allow DevOps operators to validate and use external GitHub connections"
        statements = [
          "Allow group ${local.devops_operator_group} to use devops-connection in compartment id ${local.compartment_ocid}"
        ]
      }
    ] : []
  )
}

module "vcn" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=v0.1.0"

  compartment_ocid = local.compartment_ocid
  name             = "${local.project_name}-vcn"
  vcn_cidr_blocks  = [local.vcn_cidr]

  create_internet_gateway = true

  route_tables = {
    public = {
      route_rules = [
        {
          destination        = "0.0.0.0/0"
          destination_type   = "CIDR_BLOCK"
          network_entity_key = "internet_gateway"
        }
      ]
    }
  }

  security_lists = {
    oke_api = {
      egress_rules = [
        { protocol = "6", destination = local.nodes_cidr, tcp_options = { min = 6443, max = 6443 } },
        { protocol = "6", destination = local.nodes_cidr, tcp_options = { min = 12250, max = 12250 } },
        { protocol = "6", destination = "0.0.0.0/0", tcp_options = { min = 443, max = 443 } },
        { protocol = "1", destination = local.nodes_cidr, icmp_options = { type = 3, code = 4 } }
      ]
      ingress_rules = [
        { protocol = "6", source = local.nodes_cidr, tcp_options = { min = 6443, max = 6443 } },
        { protocol = "6", source = local.nodes_cidr, tcp_options = { min = 12250, max = 12250 } },
        { protocol = "6", source = "0.0.0.0/0", tcp_options = { min = 6443, max = 6443 } },
        { protocol = "1", source = local.nodes_cidr, icmp_options = { type = 3, code = 4 } }
      ]
    }
    oke_nodes = {
      egress_rules = [
        { protocol = "all", destination = local.nodes_cidr },
        { protocol = "1", destination = "0.0.0.0/0", icmp_options = { type = 3, code = 4 } },
        { protocol = "6", destination = local.api_endpoint_cidr, tcp_options = { min = 6443, max = 6443 } },
        { protocol = "6", destination = local.api_endpoint_cidr, tcp_options = { min = 12250, max = 12250 } },
        { protocol = "6", destination = "0.0.0.0/0" }
      ]
      ingress_rules = [
        { protocol = "all", source = local.nodes_cidr },
        { protocol = "6", source = local.api_endpoint_cidr },
        { protocol = "1", source = "0.0.0.0/0", icmp_options = { type = 3, code = 4 } },
        { protocol = "6", source = "0.0.0.0/0", tcp_options = { min = 22, max = 22 } }
      ]
    }
  }

  subnets = {
    api_endpoint = {
      display_name               = "${local.project_name}-api-endpoint-subnet"
      cidr_block                 = local.api_endpoint_cidr
      route_table_key            = "public"
      prohibit_public_ip_on_vnic = false
      security_list_keys         = ["oke_api"]
    }
    lb = {
      display_name               = "${local.project_name}-lb-subnet"
      cidr_block                 = local.lb_cidr
      route_table_key            = "public"
      prohibit_public_ip_on_vnic = false
    }
    nodes = {
      display_name               = "${local.project_name}-nodes-subnet"
      cidr_block                 = local.nodes_cidr
      route_table_key            = "public"
      prohibit_public_ip_on_vnic = false
      security_list_keys         = ["oke_nodes"]
    }
  }
}

module "oke" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-oke.git?ref=v0.1.0"

  tenancy_ocid                  = local.tenancy_ocid
  compartment_ocid              = local.compartment_ocid
  cluster_type                  = "basic"
  oke_cluster_name              = local.architecture.oke.cluster_name
  k8s_version                   = local.architecture.oke.kubernetes_version
  node_linux_version            = try(local.architecture.oke.node_linux_version, "8.10")
  node_shape                    = try(local.architecture.oke.node_shape, "VM.Standard.E5.Flex")
  node_ocpus                    = try(local.architecture.oke.node_ocpus, 1)
  node_memory                   = try(local.architecture.oke.node_memory, 8)
  use_existing_vcn              = true
  use_existing_nsg              = false
  vcn_id                        = module.vcn.vcn_id
  api_endpoint_subnet_id        = module.vcn.subnet_ids["api_endpoint"]
  lb_subnet_id                  = module.vcn.subnet_ids["lb"]
  nodepool_subnet_id            = module.vcn.subnet_ids["nodes"]
  is_api_endpoint_subnet_public = true
  is_lb_subnet_public           = true
  is_nodepool_subnet_public     = true
  node_pool_count               = 1
  node_count                    = try(local.architecture.oke.node_count, 1)
}

resource "terraform_data" "ocir_pull_secret" {
  triggers_replace = {
    cluster_id       = module.oke.cluster.id
    registry         = module.ocir_image.registry
    namespace        = module.ocir_image.namespace
    ocir_user_name   = "${module.ocir_image.namespace}/${local.devops.registry.ocir_user_name}"
    ocir_password    = sha256(var.ocir_user_password)
    kubeconfig       = sha256(module.oke.KubeConfig)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
      kubeconfig_path="$(mktemp /tmp/fk-devops-oke-kubeconfig.XXXXXX)"
      trap 'rm -f "$kubeconfig_path"' EXIT

      cat > "$kubeconfig_path" <<'EOF'
${module.oke.KubeConfig}
EOF

      export KUBECONFIG="$kubeconfig_path"

      kubectl create secret docker-registry ocir-registry-secret \
        --namespace default \
        --docker-server="${module.ocir_image.registry}" \
        --docker-username="${module.ocir_image.namespace}/${local.devops.registry.ocir_user_name}" \
        --docker-password='${var.ocir_user_password}' \
        --dry-run=client -o yaml | kubectl apply -f -
    EOT
  }

  depends_on = [
    module.oke,
    module.ocir_image
  ]
}

module "ocir_image" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-ocir.git?ref=v0.1.0"

  compartment_ocid = local.compartment_ocid
  repository_name  = local.image_repository_name
  region           = local.region
  defined_tags     = local.defined_tags
  freeform_tags    = local.freeform_tags
}

module "ocir_helm" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-ocir.git?ref=v0.1.0"

  compartment_ocid = local.compartment_ocid
  repository_name  = local.helm_repository_name
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
    (local.app_connection_key) = {
      display_name = "${local.project_name}-github"
      access_token = local.devops.github.pat_secret_ocid
    }
  }

  repositories = {
    (local.app_repository_key) = {
      name           = local.devops.github.app_repository_name
      connection_key = local.app_connection_key
      repository_url = local.devops.github.app_repository_url
      branch         = local.app_branch
    }
    (local.helm_repository_key) = {
      name           = local.devops.github.helm_repository_name
      connection_key = local.app_connection_key
      repository_url = local.devops.github.helm_repository_url
      branch         = local.helm_branch
    }
  }

  deploy_artifacts = {
    (local.ocir_artifact_key) = {
      display_name               = local.image_repository_name
      argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
      deploy_artifact_type       = "DOCKER_IMAGE"
      source = {
        type           = "OCIR"
        image_uri      = "${module.ocir_image.image_prefix}:${local.helm_chart_version_prefix}-$${BUILDRUN_HASH}"
        image_digest   = " "
        repository_key = local.app_repository_key
      }
    }
    (local.helm_chart_artifact_key) = {
      display_name               = local.helm_chart_name
      argument_substitution_mode = "NONE"
      deploy_artifact_type       = "HELM_CHART"
      source = {
        type                    = "HELM_CHART"
        chart_url               = "oci://${module.ocir_helm.registry}/${module.ocir_helm.namespace}/${local.helm_repository_name}/${local.helm_chart_name}/${local.helm_chart_name}"
        deploy_artifact_version = local.helm_chart_version_prefix
      }
    }
    (local.helm_values_artifact_key) = {
      display_name               = "values.yaml"
      argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
      deploy_artifact_type       = "GENERIC_FILE"
      source = {
        type                  = "INLINE"
        base64encoded_content = base64encode(local.values_yaml)
      }
    }
  }

  deploy_environments = {
    (local.deploy_environment_key) = {
      display_name = "${local.project_name}-oke-env"
      cluster_id   = module.oke.cluster.id
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}

module "devops_pipeline" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-devops-pipeline.git?ref=v0.1.8"

  project_id = module.devops.project_id

  build_pipelines = {
    (local.build_pipeline_key) = {
      display_name = local.devops.build_pipeline.name
      description  = try(local.devops.build_pipeline.description, null)
      parameters = [
        {
          name          = "USER_AUTH_TOKEN"
          default_value = var.ocir_user_password
          description   = "OCI auth token used to push images and Helm charts."
        },
        {
          name          = "OCIR_USER_NAME"
          default_value = "${module.ocir_image.namespace}/${local.devops.registry.ocir_user_name}"
          description   = "OCI registry user used to push images and Helm charts."
        },
        {
          name          = "OCI_REGISTRY"
          default_value = module.ocir_image.registry
          description   = "OCI registry hostname for Podman and Helm login."
        },
        {
          name          = "HELM_REPO_URL"
          default_value = "oci://${module.ocir_helm.registry}/${module.ocir_helm.namespace}/${local.helm_repository_name}/${local.helm_chart_name}"
          description   = "OCI Helm chart registry URL."
        }
      ]
      stages = [
        {
          key                                = "build"
          stage_type                         = "BUILD"
          display_name                       = try(local.devops.build_pipeline.build_stage.name, "build_and_package")
          description                        = try(local.devops.build_pipeline.build_stage.description, null)
          build_spec_file                    = try(local.devops.build_pipeline.build_stage.build_spec_file, "build_spec.yaml")
          image                              = try(local.devops.build_pipeline.build_stage.image, "OL8_X86_64_STANDARD_10")
          stage_execution_timeout_in_seconds = try(local.devops.build_pipeline.build_stage.timeout_in_seconds, 36000)
          build_sources = [
            {
              name           = local.devops.github.helm_repository_name
              branch         = local.helm_branch
              repository_id  = module.devops.repository_ids[local.helm_repository_key]
              repository_url = local.devops.github.helm_repository_url
            },
            {
              name           = local.devops.github.app_repository_name
              branch         = local.app_branch
              repository_id  = module.devops.repository_ids[local.app_repository_key]
              repository_url = local.devops.github.app_repository_url
            }
          ]
        },
        {
          key              = "deliver"
          stage_type       = "DELIVER_ARTIFACT"
          display_name     = "deliver"
          description      = "deliver"
          predecessor_keys = ["build"]
          deliver_artifacts = [
            {
              artifact_id   = module.devops.deploy_artifact_ids[local.ocir_artifact_key]
              artifact_name = "APPLICATION_DOCKER_IMAGE"
            }
          ]
        }
      ]
    }
  }

  deploy_pipelines = {
    (local.deploy_pipeline_key) = {
      display_name = local.devops.deploy_pipeline.name
      description  = try(local.devops.deploy_pipeline.description, null)
      parameters = [
        {
          name          = "BUILDRUN_HASH"
          default_value = ""
          description   = "Exported build run hash used to version Helm chart and image."
        }
      ]
      stages = [
        {
          key                           = "helm"
          stage_type                    = "OKE_HELM_CHART_DEPLOYMENT"
          display_name                  = try(local.devops.deploy_pipeline.helm_stage.name, "helm_deploy")
          description                   = try(local.devops.deploy_pipeline.helm_stage.description, null)
          deploy_environment_id         = module.devops.deploy_environment_ids[local.deploy_environment_key]
          namespace                     = try(local.devops.deploy_pipeline.helm_stage.namespace, "default")
          helm_chart_deploy_artifact_id = module.devops.deploy_artifact_ids[local.helm_chart_artifact_key]
          release_name                  = local.helm_chart_name
          values_artifact_ids           = [module.devops.deploy_artifact_ids[local.helm_values_artifact_key]]
          timeout_in_seconds            = try(local.devops.deploy_pipeline.helm_stage.timeout_in_seconds, 1800)
          should_not_wait               = false
          should_reuse_values           = false
          are_hooks_enabled             = false
          max_history                   = 10
        }
      ]
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}
