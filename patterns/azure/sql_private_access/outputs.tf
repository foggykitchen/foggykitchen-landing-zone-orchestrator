output "sql_private_access" {
  description = "Azure SQL private-access outputs."
  value = {
    sql_server_id                 = module.sql.id
    sql_server_name               = module.sql.name
    sql_server_fqdn               = module.sql.fully_qualified_domain_name
    database_ids                  = module.sql.database_ids
    public_network_access_enabled = module.sql.public_network_access_enabled
    private_endpoint_id           = module.sql_private_endpoint.private_endpoint_id
    private_endpoint_name         = module.sql_private_endpoint.private_endpoint_name
    private_endpoint_private_ips  = module.sql_private_endpoint.private_ip_addresses
    private_dns_zone_id           = module.private_dns.private_dns_zone_ids[local.private_dns_zone_name]
  }
}

output "validation_host" {
  description = "Validation host connection details."
  value = {
    vm_id         = module.validation_host.vm_id
    private_ip    = module.validation_host.vm_private_ip
    public_ip     = null
    ssh_user      = local.client_admin_username
    subnet_id     = module.vnet.subnet_ids[local.client_subnet_name]
    ssh_command   = "az network bastion ssh --name ${module.bastion.bastion_name} --resource-group ${azurerm_resource_group.this.name} --target-resource-id ${module.validation_host.vm_id} --auth-type ssh-key --username ${local.client_admin_username} --ssh-key <path-to-private-key>"
    nc_validation = "nc -vz ${module.sql.fully_qualified_domain_name} 1433"
  }
}

output "bastion" {
  description = "Azure Bastion details."
  value = {
    bastion_id        = module.bastion.bastion_id
    bastion_name      = module.bastion.bastion_name
    bastion_public_ip = module.bastion.bastion_public_ip
    subnet_id         = module.vnet.subnet_ids[local.bastion_subnet_name]
  }
}

output "network" {
  description = "Network resource IDs."
  value = {
    vnet_id                      = module.vnet.vnet_id
    vnet_name                    = module.vnet.vnet_name
    client_subnet_id             = module.vnet.subnet_ids[local.client_subnet_name]
    bastion_subnet_id            = module.vnet.subnet_ids[local.bastion_subnet_name]
    private_endpoint_subnet_id   = module.vnet.subnet_ids[local.private_endpoint_subnet_name]
    nsg_id                       = module.database_nsg.id
    client_subnet_cidr           = local.client_subnet_cidr
    bastion_subnet_cidr          = local.bastion_subnet_cidr
    private_endpoint_subnet_cidr = local.private_endpoint_subnet_cidr
  }
}
