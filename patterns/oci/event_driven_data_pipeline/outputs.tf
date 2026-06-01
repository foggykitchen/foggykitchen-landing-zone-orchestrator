output "api_gateway_endpoints" {
  value = {
    fninitiator_endpoint = nonsensitive(module.api_gateway.route_endpoints[local.route_name])
  }
}

output "streaming" {
  value = {
    stream_pool_id            = module.streaming.stream_pool_id
    stream_pool_endpoint_fqdn = module.streaming.stream_pool_endpoint_fqdn
    stream_ids                = module.streaming.stream_ids
  }
}

output "service_connector" {
  value = {
    id    = module.sch.service_connector_id
    state = module.sch.service_connector_state
  }
}

output "adb" {
  value     = module.adb.adb_database
  sensitive = true
}
