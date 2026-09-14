output "cosmosdb_private_access" {
  description = "Azure Cosmos DB private-access outputs."
  value       = module.landing_zone.cosmosdb_private_access
}

output "validation_host" {
  description = "Validation host connection details."
  value       = module.landing_zone.validation_host
}

output "bastion" {
  description = "Azure Bastion details."
  value       = module.landing_zone.bastion
}

output "network" {
  description = "Network resource IDs."
  value       = module.landing_zone.network
}
