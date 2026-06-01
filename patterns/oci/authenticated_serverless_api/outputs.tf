output "api_gateway_endpoints" {
  value = {
    backend_endpoint = nonsensitive(module.api_gateway.route_endpoints[local.route_name])
  }
}

output "function_ids" {
  value = {
    fnjwtauth = module.fnjwtauth.oci_app_fn.fn_ocid
    fnbackend = module.fnbackend.oci_app_fn.fn_ocid
  }
}

output "application" {
  value = {
    id   = nonsensitive(module.fnjwtauth.oci_app_fn.fn_app_ocid)
    name = "${local.project_name}-app"
  }
}
