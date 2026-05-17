output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "hub_vnet_id" {
  value = module.hub_vnet.vnet_id
}

output "spoke_vnet_ids" {
  value = {
    for spoke_key, mod in module.spoke_vnets : spoke_key => mod.vnet_id
  }
}

output "firewall_id" {
  value = module.firewall.firewall_id
}

output "firewall_private_ip" {
  value = module.firewall.firewall_private_ip
}

output "firewall_public_ip" {
  value = module.firewall_public_ip.ip_address
}

output "route_table_ids" {
  value = module.routing.route_table_ids
}

output "vm_private_ips" {
  value = {
    for instance_key, mod in module.compute : instance_key => mod.vm_private_ip
  }
}

output "peering_ids" {
  value = {
    for spoke_key, mod in module.hub_to_spokes_peering : spoke_key => {
      hub_to_spoke = mod.peering_1_to_2_id
      spoke_to_hub = mod.peering_2_to_1_id
    }
  }
}
