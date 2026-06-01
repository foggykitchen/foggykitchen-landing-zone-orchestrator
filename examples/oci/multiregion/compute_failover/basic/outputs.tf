output "primary_site" {
  value = module.landing_zone.primary_site
}

output "standby_site" {
  value = module.landing_zone.standby_site
}

output "dns_failover" {
  value = module.landing_zone.dns_failover
}
