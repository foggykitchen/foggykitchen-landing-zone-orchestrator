module "vcn" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=v0.1.0"

  compartment_ocid = local.compartment_ocid
  name             = "${local.project_name}-vcn"
  vcn_cidr_blocks  = [local.vcn_cidr]
  dns_label        = "fkauth"

  create_internet_gateway = true
  create_nat_gateway      = true

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
    api_gateway_public = {
      ingress_rules = [
        for port in [80, 443] : {
          protocol = "6"
          source   = "0.0.0.0/0"
          tcp_options = {
            min = port
            max = port
          }
        }
      ]
      egress_rules = [
        {
          protocol    = "6"
          destination = "0.0.0.0/0"
        }
      ]
    }
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
    apigw_public = {
      cidr_block                 = local.api_gateway_subnet
      display_name               = "${local.project_name}-apigw-public"
      dns_label                  = "apigwpub"
      route_table_key            = "public"
      security_list_keys         = ["api_gateway_public"]
      prohibit_public_ip_on_vnic = false
    }
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

module "policy" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-policy.git?ref=v0.1.0"

  providers = {
    oci = oci.home
  }

  tenancy_ocid = local.tenancy_ocid

  dynamic_group = {
    name          = local.dynamic_group_name_plain
    description   = "Dynamic group for authenticated serverless API functions"
    matching_rule = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${local.compartment_ocid_plain}'}"
  }

  policies = [
    {
      name        = "${local.project_name_plain}-apigateway-policy"
      description = "Allow API Gateway to invoke Functions"
      statements = [
        "ALLOW any-user to use functions-family in compartment id ${local.compartment_ocid_plain} where ALL { request.principal.type = 'ApiGateway', request.resource.compartment.id = '${local.compartment_ocid_plain}' }"
      ]
    },
    {
      name        = "${local.project_name_plain}-functions-policy"
      description = "Allow authenticated API functions to operate in the compartment"
      statements = [
        "Allow dynamic-group ${local.dynamic_group_name_plain} to manage all-resources in compartment id ${local.compartment_ocid_plain}"
      ]
    }
  ]
}

module "fnjwtauth" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-function.git?ref=v0.2.0"

  tenancy_ocid             = local.tenancy_ocid
  region                   = local.region
  ocir_user_name           = local.functions.runtime.ocir_user_name
  ocir_user_password       = local.functions.runtime.ocir_user_password
  compartment_ocid         = local.compartment_ocid
  use_my_fn                = true
  fk_app_name              = "${local.project_name}-app"
  fk_fn_name               = local.auth_name
  fk_fn_version            = local.fnjwtauth_version
  dockerfile_content       = data.local_file.fnjwtauth_dockerfile.content
  func_py_content          = data.local_file.fnjwtauth_func_py.content
  func_yaml_content        = data.local_file.fnjwtauth_func_yaml.content
  requirements_txt_content = data.local_file.fnjwtauth_requirements_txt.content
  invoke_fn                = false
  use_oci_logging          = true
  use_my_fn_network        = true
  my_fn_subnet_ocid        = module.vcn.subnet_ids["functions_private"]
  fn_config = {
    DEBUG_MODE   = tostring(local.debug_mode)
    FN_JWT_TOKEN = local.jwt_token
  }
}

module "fnbackend" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-function.git?ref=v0.2.0"

  tenancy_ocid             = local.tenancy_ocid
  region                   = local.region
  ocir_user_name           = local.functions.runtime.ocir_user_name
  ocir_user_password       = local.functions.runtime.ocir_user_password
  compartment_ocid         = local.compartment_ocid
  use_my_fn                = true
  fk_fn_name               = local.backend_name
  fk_fn_version            = local.fnbackend_version
  dockerfile_content       = data.local_file.fnbackend_dockerfile.content
  func_py_content          = data.local_file.fnbackend_func_py.content
  func_yaml_content        = data.local_file.fnbackend_func_yaml.content
  requirements_txt_content = data.local_file.fnbackend_requirements_txt.content
  invoke_fn                = false
  use_oci_logging          = false
  use_my_fn_network        = true
  my_fn_subnet_ocid        = module.vcn.subnet_ids["functions_private"]
  use_my_fn_app            = true
  my_fn_app_ocid           = module.fnjwtauth.oci_app_fn.fn_app_ocid
  fn_config = {
    DEBUG_MODE = tostring(local.debug_mode)
  }
}

module "api_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-api-gateway.git?ref=v0.1.1"

  name             = local.api_gateway_name
  compartment_ocid = local.compartment_ocid
  subnet_id        = module.vcn.subnet_ids["apigw_public"]
  endpoint_type    = "PUBLIC"
  path_prefix      = local.api_path_prefix
  defined_tags     = local.defined_tags
  freeform_tags    = local.freeform_tags

  custom_authentication = {
    function_id  = module.fnjwtauth.oci_app_fn.fn_ocid
    token_header = local.token_header
  }

  routes = [
    {
      name    = local.route_name
      path    = local.route_path
      methods = ["POST"]
      backend = {
        type        = "ORACLE_FUNCTIONS_BACKEND"
        function_id = module.fnbackend.oci_app_fn.fn_ocid
      }
    }
  ]
}
