locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  functions    = local.config.functions

  tenancy_ocid     = local.cloud.tenancy_ocid
  compartment_ocid = local.cloud.compartment_ocid
  iam_home_region  = local.cloud.home_region
  region           = try(local.cloud.workload_region, local.cloud.home_region)
  defined_tags     = try(local.landing_zone.defined_tags, {})
  freeform_tags    = try(local.landing_zone.freeform_tags, {})

  compartment_ocid_plain   = nonsensitive(local.compartment_ocid)
  project_name_plain       = nonsensitive(local.functions.project.name)
  dynamic_group_name_plain = nonsensitive(try(local.functions.iam.dynamic_group_name, "${local.functions.project.name}-dg"))

  vcn_cidr            = try(local.architecture.network.vcn_cidr, "10.90.0.0/16")
  api_gateway_subnet  = try(local.architecture.network.api_gateway_subnet_cidr, "10.90.10.0/24")
  functions_subnet    = try(local.architecture.network.functions_subnet_cidr, "10.90.20.0/24")
  project_name        = local.functions.project.name
  project_description = try(local.functions.project.description, null)
  dynamic_group_name  = try(local.functions.iam.dynamic_group_name, "${local.project_name}-dg")
  functions_base_path = local.functions.source_path
  debug_mode          = try(local.functions.runtime.debug_mode, true)

  api_gateway_name = try(local.functions.api.gateway_name, "${local.project_name}-gateway")
  api_path_prefix  = try(local.functions.api.path_prefix, "/v1")
  route_name       = try(local.functions.api.route_name, "backend")
  route_path       = try(local.functions.api.route_path, "/backend")
  token_header     = try(local.functions.api.token_header, "token")

  auth_name    = try(local.functions.runtime.auth_function_name, "fnjwtauth")
  backend_name = try(local.functions.runtime.backend_function_name, "fnbackend")
  jwt_token    = local.functions.security.jwt_token

  fnjwtauth_version = substr(
    sha1(join("", [
      data.local_file.fnjwtauth_dockerfile.content,
      data.local_file.fnjwtauth_func_py.content,
      data.local_file.fnjwtauth_func_yaml.content,
      data.local_file.fnjwtauth_requirements_txt.content,
    ])),
    0,
    12,
  )
  fnbackend_version = substr(
    sha1(join("", [
      data.local_file.fnbackend_dockerfile.content,
      data.local_file.fnbackend_func_py.content,
      data.local_file.fnbackend_func_yaml.content,
      data.local_file.fnbackend_requirements_txt.content,
    ])),
    0,
    12,
  )
}
