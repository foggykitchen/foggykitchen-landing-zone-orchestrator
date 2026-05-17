output "resource_group_name" {
  value = module.landing_zone.resource_group_name
}

output "hub_vnet_id" {
  value = module.landing_zone.hub_vnet_id
}

output "spoke_vnet_ids" {
  value = module.landing_zone.spoke_vnet_ids
}

output "firewall_id" {
  value = module.landing_zone.firewall_id
}

output "firewall_private_ip" {
  value = module.landing_zone.firewall_private_ip
}

output "firewall_public_ip" {
  value = module.landing_zone.firewall_public_ip
}

output "route_table_ids" {
  value = module.landing_zone.route_table_ids
}

output "vm_private_ips" {
  value = module.landing_zone.vm_private_ips
}
