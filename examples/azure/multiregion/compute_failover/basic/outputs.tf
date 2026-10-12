output "primary_site" {
  description = "Primary Azure region outputs."
  value       = module.landing_zone.primary_site
}

output "standby_site" {
  description = "Standby Azure region outputs."
  value       = module.landing_zone.standby_site
}

output "frontdoor_failover" {
  description = "Azure Front Door failover outputs."
  value       = module.landing_zone.frontdoor_failover
}
