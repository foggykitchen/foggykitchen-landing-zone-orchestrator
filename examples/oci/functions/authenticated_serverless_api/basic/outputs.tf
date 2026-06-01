output "api_gateway_endpoints" {
  value = module.landing_zone.api_gateway_endpoints
}

output "function_ids" {
  value = module.landing_zone.function_ids
}

output "application" {
  value     = module.landing_zone.application
  sensitive = true
}
