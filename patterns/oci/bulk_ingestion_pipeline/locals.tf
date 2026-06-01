locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  functions    = local.config.functions
  data_layer   = local.config.data

  tenancy_ocid     = local.cloud.tenancy_ocid
  compartment_ocid = local.cloud.compartment_ocid
  iam_home_region  = local.cloud.home_region
  region           = try(local.cloud.workload_region, local.cloud.home_region)
  defined_tags     = try(local.landing_zone.defined_tags, {})
  freeform_tags    = try(local.landing_zone.freeform_tags, {})

  compartment_ocid_plain   = nonsensitive(local.compartment_ocid)
  project_name_plain       = nonsensitive(local.functions.project.name)
  dynamic_group_name_plain = nonsensitive(try(local.functions.iam.dynamic_group_name, "${local.functions.project.name}-dg"))

  vcn_cidr            = try(local.architecture.network.vcn_cidr, "10.80.0.0/16")
  functions_subnet    = try(local.architecture.network.functions_subnet_cidr, "10.80.20.0/24")
  project_name        = local.functions.project.name
  project_description = try(local.functions.project.description, null)
  dynamic_group_name  = try(local.functions.iam.dynamic_group_name, "${local.project_name}-dg")
  functions_base_path = local.functions.source_path
  debug_mode          = try(local.functions.runtime.debug_mode, true)

  bucket_key  = "ingestion"
  bucket_name = try(local.data_layer.objectstorage.bucket_name, "${local.project_name}-bucket")

  stream_key       = "iot"
  stream_pool_name = try(local.functions.streaming.stream_pool_name, "${local.project_name}-pool")
  stream_name      = try(local.functions.streaming.stream_name, "${local.project_name}-stream")

  adb_database_db_name  = try(local.data_layer.adb.database_name, "FoggyKitchenADB")
  adb_app_user_name     = try(local.data_layer.adb.app_user_name, "APPUSER")
  adb_app_user_password = local.data_layer.adb.app_user_password
  adb_admin_password    = local.data_layer.adb.admin_password
  adb_sqlnet_alias      = try(local.data_layer.adb.sqlnet_alias, "foggykitchenadb_medium")

  event_rule_name = try(local.data_layer.objectstorage.event_rule_name, "${local.project_name}-object-create")

  bulkload_name  = try(local.functions.runtime.bulkload_name, "fnbulkload")
  collector_name = try(local.functions.runtime.collector_name, "fncollector")
  adb_setup_name = try(local.functions.runtime.adb_setup_name, "fnadbsetup")

  fnbulkload_version = substr(
    sha1(join("", [
      data.local_file.fnbulkload_dockerfile.content,
      data.local_file.fnbulkload_func_py.content,
      data.local_file.fnbulkload_func_yaml.content,
      data.local_file.fnbulkload_requirements_txt.content,
    ])),
    0,
    12,
  )
  fncollector_version = substr(
    sha1(join("", [
      data.local_file.fncollector_dockerfile.content,
      data.local_file.fncollector_func_py.content,
      data.local_file.fncollector_func_yaml.content,
      data.local_file.fncollector_requirements_txt.content,
    ])),
    0,
    12,
  )
  fnadbsetup_version = substr(
    sha1(join("", [
      data.local_file.fnadbsetup_dockerfile.content,
      data.local_file.fnadbsetup_func_py.content,
      data.local_file.fnadbsetup_func_yaml.content,
      data.local_file.fnadbsetup_requirements_txt.content,
    ])),
    0,
    12,
  )
}
