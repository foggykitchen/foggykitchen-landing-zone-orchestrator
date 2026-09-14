output "postgresql_private_access" {
  value = {
    flexible_server_id            = module.postgresql.id
    flexible_server_name          = module.postgresql.name
    flexible_server_fqdn          = module.postgresql.fqdn
    database_ids                  = module.postgresql.database_ids
    delegated_subnet_id           = local.is_delegated_subnet ? module.vnet.subnet_ids[local.database_subnet_name] : null
    private_endpoint_subnet_id    = local.is_private_endpoint ? module.vnet.subnet_ids[local.private_endpoint_subnet_name] : null
    private_endpoint_id           = local.is_private_endpoint ? module.postgresql_private_endpoint[0].private_endpoint_id : null
    private_endpoint_name         = local.is_private_endpoint ? module.postgresql_private_endpoint[0].private_endpoint_name : null
    private_endpoint_private_ips  = local.is_private_endpoint ? data.azurerm_network_interface.postgresql_private_endpoint[0].private_ip_addresses : []
    private_dns_zone_id           = module.private_dns.private_dns_zone_ids[local.private_dns_zone_name]
    public_network_access_enabled = module.postgresql.public_network_access_enabled
  }
}

output "validation_host" {
  value = {
    vm_id           = module.validation_host.vm_id
    public_ip       = null
    private_ip      = module.validation_host.vm_private_ip
    ssh_user        = local.client_admin_username
    subnet_id       = module.vnet.subnet_ids[local.client_subnet_name]
    ssh_command     = "az network bastion ssh --name ${module.bastion.bastion_name} --resource-group ${azurerm_resource_group.this.name} --target-resource-id ${module.validation_host.vm_id} --auth-type ssh-key --username ${local.client_admin_username} --ssh-key <path-to-private-key>"
    nc_validation   = "nc -vz ${module.postgresql.fqdn} 5432"
    psql_validation = "psql \"host=${module.postgresql.fqdn} port=5432 dbname=${local.postgresql_database_name} user=${local.postgresql_admin_login} sslmode=require\""
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
    client_subnet_id             = module.vnet.subnet_ids[local.client_subnet_name]
    bastion_subnet_id            = module.vnet.subnet_ids[local.bastion_subnet_name]
    delegated_subnet_id          = local.is_delegated_subnet ? module.vnet.subnet_ids[local.database_subnet_name] : null
    private_endpoint_subnet_id   = local.is_private_endpoint ? module.vnet.subnet_ids[local.private_endpoint_subnet_name] : null
    client_subnet_cidr           = local.client_subnet_cidr
    bastion_subnet_cidr          = local.bastion_subnet_cidr
    database_subnet_cidr         = local.is_delegated_subnet ? local.database_subnet_cidr : null
    private_endpoint_subnet_cidr = local.is_private_endpoint ? local.private_endpoint_subnet_cidr : null
    nsg_id                       = module.database_nsg.id
  }
}
