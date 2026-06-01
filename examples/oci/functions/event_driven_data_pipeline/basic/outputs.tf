output "api_gateway_endpoints" {
  value = nonsensitive(module.landing_zone.api_gateway_endpoints)
}

output "streaming" {
  value = module.landing_zone.streaming
}

output "service_connector" {
  value = module.landing_zone.service_connector
}

output "adb" {
  value     = module.landing_zone.adb
  sensitive = true
}
