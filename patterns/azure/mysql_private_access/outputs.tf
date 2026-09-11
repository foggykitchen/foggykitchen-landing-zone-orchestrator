output "mysql_private_access" {
  value = {
    flexible_server_id            = module.mysql.id
    flexible_server_name          = module.mysql.name
    flexible_server_fqdn          = module.mysql.fqdn
    database_ids                  = module.mysql.database_ids
    delegated_subnet_id           = module.vnet.subnet_ids[local.database_subnet_name]
    private_dns_zone_id           = module.private_dns.private_dns_zone_ids[local.private_dns_zone_name]
    public_network_access_enabled = module.mysql.public_network_access_enabled
  }
}

output "validation_host" {
  value = {
    vm_id            = module.validation_host.vm_id
    public_ip        = null
    private_ip       = module.validation_host.vm_private_ip
    ssh_user         = local.client_admin_username
    subnet_id        = module.vnet.subnet_ids[local.client_subnet_name]
    ssh_command      = "az network bastion ssh --name ${module.bastion.bastion_name} --resource-group ${azurerm_resource_group.this.name} --target-resource-id ${module.validation_host.vm_id} --auth-type ssh-key --username ${local.client_admin_username} --ssh-key <path-to-private-key>"
    nc_validation    = "nc -vz ${module.mysql.fqdn} 3306"
    mysql_validation = "mysql --host=${module.mysql.fqdn} --port=3306 --user=${local.mysql_admin_login} --ssl-mode=REQUIRED --database=${local.mysql_database_name} --password"
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
    vnet_id              = module.vnet.vnet_id
    vnet_name            = module.vnet.vnet_name
    client_subnet_id     = module.vnet.subnet_ids[local.client_subnet_name]
    bastion_subnet_id    = module.vnet.subnet_ids[local.bastion_subnet_name]
    delegated_subnet_id  = module.vnet.subnet_ids[local.database_subnet_name]
    client_subnet_cidr   = local.client_subnet_cidr
    bastion_subnet_cidr  = local.bastion_subnet_cidr
    database_subnet_cidr = local.database_subnet_cidr
    nsg_id               = module.database_nsg.id
  }
}
