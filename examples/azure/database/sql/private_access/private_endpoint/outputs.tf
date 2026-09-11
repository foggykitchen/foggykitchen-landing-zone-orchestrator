output "sql_private_access" {
  value = module.landing_zone.sql_private_access
}

output "validation_host" {
  value = module.landing_zone.validation_host
}

output "bastion" {
  value = module.landing_zone.bastion
}

output "network" {
  value = module.landing_zone.network
}
