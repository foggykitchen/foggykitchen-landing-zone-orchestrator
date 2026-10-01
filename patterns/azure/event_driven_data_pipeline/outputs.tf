output "resource_group_name" {
  description = "Azure Resource Group name."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "VNet resource ID."
  value       = module.vnet.vnet_id
}

output "subnet_ids" {
  description = "Subnet IDs keyed by subnet name."
  value       = module.vnet.subnet_ids
}

output "function_app" {
  description = "Function App identifiers."
  value = {
    id               = module.function_app.id
    name             = module.function_app.name
    default_hostname = module.function_app.default_hostname
    principal_id     = module.function_app.principal_id
  }
}

output "function_ids" {
  description = "Azure Function resource IDs for the runtime functions."
  value = {
    fninitiator = "${module.function_app.id}/functions/${local.initiator_name}"
    fncollector = "${module.function_app.id}/functions/${local.collector_name}"
    fnvalidator = "${module.function_app.id}/functions/${local.validator_name}"
  }
}

output "api_management" {
  description = "API Management public endpoint details."
  value = {
    id              = module.api_management.api_management_id
    name            = module.api_management.api_management_name
    gateway_url     = module.api_management.gateway_url
    route_endpoints = module.api_management.route_endpoints
  }
}

output "event_hub" {
  description = "Event Hubs namespace and hub metadata."
  value = {
    namespace_id   = module.event_hub.namespace_id
    namespace_name = module.event_hub.namespace_name
    event_hubs     = module.event_hub.event_hubs
  }
}

output "storage" {
  description = "Function host Storage Account details."
  value = {
    storage_account_id   = module.storage.storage_account_id
    storage_account_name = module.storage.storage_account_name
  }
}

output "postgresql" {
  description = "PostgreSQL Flexible Server and database details."
  value = {
    id                  = module.postgresql.id
    name                = module.postgresql.name
    fqdn                = module.postgresql.fqdn
    database_ids        = module.postgresql.database_ids
    delegated_subnet_id = module.postgresql.delegated_subnet_id
    private_dns_zone_id = module.postgresql.private_dns_zone_id
  }
}

output "validation_notes" {
  description = "Manual verification hints for the example."
  value = {
    api_entrypoint      = module.api_management.route_endpoints[local.api_route_name]
    validator_endpoint  = module.api_management.route_endpoints[local.api_validator_name]
    expected_flow       = "APIM -> fninitiator -> Event Hub -> fncollector -> PostgreSQL"
    postgresql_endpoint = "${module.postgresql.fqdn}:5432"
  }
}
