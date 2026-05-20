output "resource_group_name" {
  value = module.hub_spoke.resource_group_name
}

output "hub_vnet_id" {
  value = module.hub_spoke.hub_vnet_id
}

output "spoke_vnet_ids" {
  value = module.hub_spoke.spoke_vnet_ids
}

output "subnet_ids" {
  value = module.hub_spoke.subnet_ids
}

output "nat_public_ip" {
  value = module.hub_spoke.nat_public_ip
}

output "bastion_name" {
  value = module.hub_spoke.bastion_name
}

output "route_table_ids" {
  value = module.hub_spoke.route_table_ids
}

output "private_dns_zone_ids" {
  value = module.hub_spoke.private_dns_zone_ids
}

output "vm_private_ips" {
  value = merge(
    module.hub_spoke.vm_private_ips,
    length(module.compute_storage_mounts) > 0 ? { app01 = module.compute_storage_mounts[0].vm_private_ip } : {}
  )
}

output "internal_load_balancer_private_ip" {
  value = module.hub_spoke.internal_load_balancer_private_ip
}

output "storage_account_id" {
  value = try(module.storage[0].storage_account_id, null)
}

output "storage_account_name" {
  value = try(module.storage[0].storage_account_name, null)
}

output "storage_file_share_names" {
  value = try(module.storage[0].file_share_names, [])
}

output "storage_blob_endpoint" {
  value = try(module.storage[0].primary_blob_endpoint, null)
}

output "storage_file_endpoint" {
  value = try(module.storage[0].primary_file_endpoint, null)
}

output "private_endpoint_ids" {
  value = {
    for endpoint_key, mod in module.private_endpoints : endpoint_key => mod.private_endpoint_id
  }
}

output "private_endpoint_private_ips" {
  value = {
    for endpoint_key, mod in module.private_endpoints : endpoint_key => mod.private_ip_addresses
  }
}
