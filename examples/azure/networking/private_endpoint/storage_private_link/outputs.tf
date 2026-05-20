output "resource_group_name" {
  value = module.landing_zone.resource_group_name
}

output "hub_vnet_id" {
  value = module.landing_zone.hub_vnet_id
}

output "spoke_vnet_ids" {
  value = module.landing_zone.spoke_vnet_ids
}

output "subnet_ids" {
  value = module.landing_zone.subnet_ids
}

output "bastion_name" {
  value = module.landing_zone.bastion_name
}

output "route_table_ids" {
  value = module.landing_zone.route_table_ids
}

output "vm_private_ips" {
  value = module.landing_zone.vm_private_ips
}

output "storage_account_id" {
  value = module.landing_zone.storage_account_id
}

output "storage_account_name" {
  value = module.landing_zone.storage_account_name
}

output "storage_file_share_names" {
  value = module.landing_zone.storage_file_share_names
}

output "private_endpoint_ids" {
  value = module.landing_zone.private_endpoint_ids
}

output "private_endpoint_private_ips" {
  value = module.landing_zone.private_endpoint_private_ips
}

output "private_dns_zone_ids" {
  value = module.landing_zone.private_dns_zone_ids
}

output "generated_admin_ssh_private_key_pem" {
  value     = try(tls_private_key.generated[0].private_key_pem, null)
  sensitive = true
}
