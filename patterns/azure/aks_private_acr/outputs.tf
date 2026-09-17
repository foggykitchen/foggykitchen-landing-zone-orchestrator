output "aks" {
  value = {
    cluster_id          = module.aks.cluster_id
    cluster_name        = module.aks.cluster_name
    resource_group_name = module.aks.resource_group_name
    node_resource_group = module.aks.node_resource_group
    fqdn                = module.aks.fqdn
    private_fqdn        = module.aks.private_fqdn
    subnet_id           = module.aks.subnet_id
    kubelet_object_id   = module.aks.kubelet_object_id
  }
}

output "jump_host" {
  value = {
    vm_id         = module.jump_host.vm_id
    public_ip     = null
    private_ip    = module.jump_host.vm_private_ip
    ssh_user      = local.jump_admin_username
    subnet_id     = module.vnet.subnet_ids[local.jump_subnet_name]
    ssh_command   = "az network bastion ssh --name ${module.bastion.bastion_name} --resource-group ${azurerm_resource_group.this.name} --target-resource-id ${module.jump_host.vm_id} --auth-type ssh-key --username ${local.jump_admin_username} --ssh-key <path-to-private-key>"
    dns_check     = "getent hosts ${module.aks.private_fqdn}"
    tcp_check     = "nc -vz ${module.aks.private_fqdn} 443"
    acr_dns_check = "getent hosts ${module.acr.acr_login_server}"
    acr_tcp_check = "nc -vz ${module.acr.acr_login_server} 443"
  }
}

output "acr" {
  value = {
    acr_id                        = module.acr.acr_id
    acr_name                      = module.acr.acr_name
    acr_login_server              = module.acr.acr_login_server
    public_network_access_enabled = false
    private_endpoint_id           = module.acr_private_endpoint.private_endpoint_id
    private_endpoint_name         = module.acr_private_endpoint.private_endpoint_name
    private_endpoint_private_ips  = module.acr_private_endpoint.private_ip_addresses
    private_dns_zone_id           = module.private_dns.private_dns_zone_ids[local.acr_private_dns_zone_name]
    private_dns_zone_name         = local.acr_private_dns_zone_name
  }
}

output "bastion" {
  value = {
    bastion_id        = module.bastion.bastion_id
    bastion_name      = module.bastion.bastion_name
    bastion_public_ip = module.bastion.bastion_public_ip
    subnet_id         = module.vnet.subnet_ids[local.bastion_subnet_name]
  }
}

output "network" {
  value = {
    vnet_id                      = module.vnet.vnet_id
    vnet_name                    = module.vnet.vnet_name
    node_subnet_id               = module.vnet.subnet_ids[local.node_subnet_name]
    jump_subnet_id               = module.vnet.subnet_ids[local.jump_subnet_name]
    private_endpoint_subnet_id   = module.vnet.subnet_ids[local.pe_subnet_name]
    bastion_subnet_id            = module.vnet.subnet_ids[local.bastion_subnet_name]
    node_subnet_cidr             = local.node_subnet_cidr
    jump_subnet_cidr             = local.jump_subnet_cidr
    private_endpoint_subnet_cidr = local.pe_subnet_cidr
    bastion_subnet_cidr          = local.bastion_subnet_cidr
    node_nsg_id                  = module.node_nsg.id
    jump_nsg_id                  = module.jump_nsg.id
    route_table_id               = module.routing.route_table_ids[local.route_table_name]
    nat_gateway_id               = module.nat_gateway.nat_gateway_id
    nat_public_ip                = module.nat_gateway_public_ip.ip_address
  }
}
