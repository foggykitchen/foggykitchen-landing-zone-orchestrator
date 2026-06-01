data "local_file" "fnbulkload_dockerfile" {
  filename = "${local.functions_base_path}/fnbulkload/Dockerfile"
}

data "local_file" "fnbulkload_func_py" {
  filename = "${local.functions_base_path}/fnbulkload/func.py"
}

data "local_file" "fnbulkload_func_yaml" {
  filename = "${local.functions_base_path}/fnbulkload/func.yaml"
}

data "local_file" "fnbulkload_requirements_txt" {
  filename = "${local.functions_base_path}/fnbulkload/requirements.txt"
}

data "local_file" "fncollector_dockerfile" {
  filename = "${local.functions_base_path}/fncollector/Dockerfile"
}

data "local_file" "fncollector_func_py" {
  filename = "${local.functions_base_path}/fncollector/func.py"
}

data "local_file" "fncollector_func_yaml" {
  filename = "${local.functions_base_path}/fncollector/func.yaml"
}

data "local_file" "fncollector_requirements_txt" {
  filename = "${local.functions_base_path}/fncollector/requirements.txt"
}

data "local_file" "fnadbsetup_dockerfile" {
  filename = "${local.functions_base_path}/fnadbsetup/Dockerfile"
}

data "local_file" "fnadbsetup_func_py" {
  filename = "${local.functions_base_path}/fnadbsetup/func.py"
}

data "local_file" "fnadbsetup_func_yaml" {
  filename = "${local.functions_base_path}/fnadbsetup/func.yaml"
}

data "local_file" "fnadbsetup_requirements_txt" {
  filename = "${local.functions_base_path}/fnadbsetup/requirements.txt"
}

module "vcn" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=v0.1.0"

  compartment_ocid = local.compartment_ocid
  name             = "${local.project_name}-vcn"
  vcn_cidr_blocks  = [local.vcn_cidr]
  dns_label        = "fkbulk"

  create_internet_gateway = true
  create_nat_gateway      = true

  route_tables = {
    private = {
      route_rules = [
        {
          destination        = "0.0.0.0/0"
          destination_type   = "CIDR_BLOCK"
          network_entity_key = "nat_gateway"
        }
      ]
    }
  }

  security_lists = {
    functions_private = {
      ingress_rules = [
        {
          protocol = "6"
          source   = local.vcn_cidr
        }
      ]
      egress_rules = [
        {
          protocol    = "6"
          destination = "0.0.0.0/0"
        }
      ]
    }
  }

  subnets = {
    functions_private = {
      cidr_block                 = local.functions_subnet
      display_name               = "${local.project_name}-functions-private"
      dns_label                  = "fnpriv"
      route_table_key            = "private"
      security_list_keys         = ["functions_private"]
      prohibit_internet_ingress  = true
      prohibit_public_ip_on_vnic = true
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}

module "objectstorage" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-objectstorage.git?ref=v0.1.1"

  compartment_ocid = local.compartment_ocid
  name             = local.project_name

  buckets = {
    (local.bucket_key) = {
      name                  = local.bucket_name
      access_type           = "NoPublicAccess"
      object_events_enabled = true
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}

module "streaming" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-streaming.git?ref=v0.1.0"

  name             = local.project_name
  compartment_ocid = local.compartment_ocid
  stream_pool_name = local.stream_pool_name
  streams = {
    (local.stream_key) = {
      name               = local.stream_name
      partitions         = 1
      retention_in_hours = 24
    }
  }
}

module "adb" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-adb.git?ref=v1.4"

  compartment_ocid          = local.compartment_ocid
  adb_password              = local.adb_admin_password
  adb_database_db_name      = local.adb_database_db_name
  adb_database_display_name = local.adb_database_db_name
  adb_database_db_workload  = "OLTP"
  adb_free_tier             = true
  adb_private_endpoint      = false
  use_existing_vcn          = true

  defined_tags = local.defined_tags
}

module "policy" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-policy.git?ref=v0.1.0"

  providers = {
    oci = oci.home
  }

  tenancy_ocid = local.tenancy_ocid

  dynamic_group = {
    name          = local.dynamic_group_name_plain
    description   = "Dynamic group for bulk ingestion pipeline functions"
    matching_rule = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${local.compartment_ocid_plain}'}"
  }

  policies = [
    {
      name        = "${local.project_name_plain}-functions-policy"
      description = "Allow bulk ingestion functions to access Object Storage, Streaming, and Autonomous Database"
      statements = [
        "Allow dynamic-group ${local.dynamic_group_name_plain} to manage all-resources in compartment id ${local.compartment_ocid_plain}",
        "Allow dynamic-group ${local.dynamic_group_name_plain} to use stream-push in compartment id ${local.compartment_ocid_plain}",
        "Allow dynamic-group ${local.dynamic_group_name_plain} to use database-family in compartment id ${local.compartment_ocid_plain}",
        "Allow dynamic-group ${local.dynamic_group_name_plain} to manage autonomous-database in compartment id ${local.compartment_ocid_plain}",
        "Allow dynamic-group ${local.dynamic_group_name_plain} to read buckets in compartment id ${local.compartment_ocid_plain}"
      ]
    },
    {
      name        = "${local.project_name_plain}-sch-policy"
      description = "Allow Service Connector Hub to consume the stream and invoke the collector function"
      statements = [
        "Allow any-user to {STREAM_READ, STREAM_CONSUME} in compartment id ${local.compartment_ocid_plain} where all {request.principal.type='serviceconnector', target.stream.id='${module.streaming.stream_ids[local.stream_key]}', request.principal.compartment.id='${local.compartment_ocid_plain}'}",
        "Allow any-user to use fn-function in compartment id ${local.compartment_ocid_plain} where all {request.principal.type='serviceconnector', request.principal.compartment.id='${local.compartment_ocid_plain}'}",
        "Allow any-user to use fn-invocation in compartment id ${local.compartment_ocid_plain} where all {request.principal.type='serviceconnector', request.principal.compartment.id='${local.compartment_ocid_plain}'}"
      ]
    },
    {
      name        = "${local.project_name_plain}-event-policy"
      description = "Allow OCI Events to invoke the bulk loader function"
      statements = [
        "ALLOW any-user to use fn-function in compartment id ${local.compartment_ocid_plain} where ALL { request.principal.type = 'eventrule', request.principal.compartment.id = '${local.compartment_ocid_plain}' }",
        "ALLOW any-user to use fn-invocation in compartment id ${local.compartment_ocid_plain} where ALL { request.principal.type = 'eventrule', request.principal.compartment.id = '${local.compartment_ocid_plain}' }"
      ]
    }
  ]
}

module "fnbulkload" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-function.git?ref=v0.2.0"

  tenancy_ocid             = local.tenancy_ocid
  region                   = local.region
  ocir_user_name           = local.functions.runtime.ocir_user_name
  ocir_user_password       = local.functions.runtime.ocir_user_password
  compartment_ocid         = local.compartment_ocid
  use_my_fn                = true
  fk_app_name              = "${local.project_name}-app"
  fk_fn_name               = local.bulkload_name
  fk_fn_version            = local.fnbulkload_version
  dockerfile_content       = data.local_file.fnbulkload_dockerfile.content
  func_py_content          = data.local_file.fnbulkload_func_py.content
  func_yaml_content        = data.local_file.fnbulkload_func_yaml.content
  requirements_txt_content = data.local_file.fnbulkload_requirements_txt.content
  invoke_fn                = false
  use_oci_logging          = false
  use_my_fn_network        = true
  my_fn_subnet_ocid        = module.vcn.subnet_ids["functions_private"]
  fn_timeout_in_seconds    = 300
  fn_config = {
    DEBUG_MODE      = tostring(local.debug_mode)
    STREAM_OCID     = module.streaming.stream_ids[local.stream_key]
    STREAM_ENDPOINT = module.streaming.stream_pool_endpoint_fqdn
  }
}

module "fncollector" {
  depends_on = [module.adb]
  source     = "git::https://github.com/foggykitchen/terraform-oci-fk-function.git?ref=v0.2.0"

  tenancy_ocid       = local.tenancy_ocid
  region             = local.region
  ocir_user_name     = local.functions.runtime.ocir_user_name
  ocir_user_password = local.functions.runtime.ocir_user_password
  compartment_ocid   = local.compartment_ocid
  use_my_fn          = true
  fk_fn_name         = local.collector_name
  fk_fn_version      = local.fncollector_version
  dockerfile_content = data.local_file.fncollector_dockerfile.content
  func_py_content = replace(
    replace(data.local_file.fncollector_func_py.content, "__ADB_WALLET_CONTENT__", module.adb.adb_database.adb_wallet_content),
    "__ADB_WALLET_PASSWORD__",
    module.adb.adb_database.adb_wallet_password,
  )
  func_yaml_content        = data.local_file.fncollector_func_yaml.content
  requirements_txt_content = data.local_file.fncollector_requirements_txt.content
  invoke_fn                = false
  use_oci_logging          = false
  use_my_fn_app            = true
  my_fn_app_ocid           = module.fnbulkload.oci_app_fn.fn_app_ocid
  use_my_fn_network        = true
  my_fn_subnet_ocid        = module.vcn.subnet_ids["functions_private"]
  fn_timeout_in_seconds    = 300
  fn_config = {
    DEBUG_MODE            = tostring(local.debug_mode)
    STREAM_OCID           = module.streaming.stream_ids[local.stream_key]
    STREAM_ENDPOINT       = module.streaming.stream_pool_endpoint_fqdn
    ADB_OCID              = module.adb.adb_database.adb_database_id
    ADB_APP_USER_NAME     = local.adb_app_user_name
    ADB_APP_USER_PASSWORD = local.adb_app_user_password
    ADB_SQLNET_ALIAS      = local.adb_sqlnet_alias
  }
}

module "fnadbsetup" {
  depends_on = [module.adb]
  source     = "git::https://github.com/foggykitchen/terraform-oci-fk-function.git?ref=v0.2.0"

  tenancy_ocid       = local.tenancy_ocid
  region             = local.region
  ocir_user_name     = local.functions.runtime.ocir_user_name
  ocir_user_password = local.functions.runtime.ocir_user_password
  compartment_ocid   = local.compartment_ocid
  use_my_fn          = true
  fk_fn_name         = local.adb_setup_name
  fk_fn_version      = local.fnadbsetup_version
  dockerfile_content = data.local_file.fnadbsetup_dockerfile.content
  func_py_content = replace(
    replace(data.local_file.fnadbsetup_func_py.content, "__ADB_WALLET_CONTENT__", module.adb.adb_database.adb_wallet_content),
    "__ADB_WALLET_PASSWORD__",
    module.adb.adb_database.adb_wallet_password,
  )
  func_yaml_content        = data.local_file.fnadbsetup_func_yaml.content
  requirements_txt_content = data.local_file.fnadbsetup_requirements_txt.content
  invoke_fn                = true
  use_oci_logging          = false
  use_my_fn_app            = true
  my_fn_app_ocid           = module.fnbulkload.oci_app_fn.fn_app_ocid
  use_my_fn_network        = true
  my_fn_subnet_ocid        = module.vcn.subnet_ids["functions_private"]
  fn_config = {
    DEBUG_MODE            = tostring(local.debug_mode)
    ADB_OCID              = module.adb.adb_database.adb_database_id
    ADB_ADMIN_PASSWORD    = local.adb_admin_password
    ADB_APP_USER_NAME     = local.adb_app_user_name
    ADB_APP_USER_PASSWORD = local.adb_app_user_password
    ADB_SQLNET_ALIAS      = local.adb_sqlnet_alias
  }
}

module "sch" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-sch.git?ref=v0.1.0"

  name             = local.project_name
  compartment_ocid = local.compartment_ocid
  description      = "Service Connector Hub for bulk ingestion pipeline"

  streaming_source = {
    stream_id   = module.streaming.stream_ids[local.stream_key]
    cursor_kind = "TRIM_HORIZON"
  }

  functions_target = {
    function_id = module.fncollector.oci_app_fn.fn_ocid
  }
}

module "event" {
  depends_on = [module.policy, module.fnbulkload]
  source     = "git::https://github.com/foggykitchen/terraform-oci-fk-event.git?ref=v0.1.0"

  name             = local.project_name
  rule_name        = local.event_rule_name
  compartment_ocid = local.compartment_ocid
  description      = "Invoke the bulk loader function when a new object is created in the ingestion bucket"
  condition = jsonencode({
    eventType = "com.oraclecloud.objectstorage.createobject"
    data = {
      additionalDetails = {
        bucketId = module.objectstorage.bucket_ids[local.bucket_key]
      }
    }
  })
  actions = [
    {
      action_type = "FAAS"
      description = "Invoke fnbulkload when a JSON object is uploaded"
      function_id = module.fnbulkload.oci_app_fn.fn_ocid
    }
  ]

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}
