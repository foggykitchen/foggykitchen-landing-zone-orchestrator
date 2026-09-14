output "cosmosdb_private_access" {
  description = "Azure Cosmos DB private-access outputs."
  value = {
    account_id       = module.cosmosdb.id
    account_name     = module.cosmosdb.name
    endpoint         = module.cosmosdb.endpoint
    read_endpoints   = module.cosmosdb.read_endpoints
    write_endpoints  = module.cosmosdb.write_endpoints
    sql_database_ids = module.cosmosdb.sql_database_ids
    sql_container_ids = {
      (azurerm_cosmosdb_sql_container.this.name) = azurerm_cosmosdb_sql_container.this.id
    }
    public_network_access_enabled = false
    private_endpoint_id           = module.cosmosdb_private_endpoint.private_endpoint_id
    private_endpoint_name         = module.cosmosdb_private_endpoint.private_endpoint_name
    private_endpoint_private_ips  = module.cosmosdb_private_endpoint.private_ip_addresses
    private_dns_zone_id           = module.private_dns.private_dns_zone_ids[local.private_dns_zone_name]
  }
}

output "validation_host" {
  description = "Validation host connection details."
  value = {
    vm_id           = module.validation_host.vm_id
    private_ip      = module.validation_host.vm_private_ip
    public_ip       = null
    ssh_user        = local.client_admin_username
    subnet_id       = module.vnet.subnet_ids[local.client_subnet_name]
    ssh_command     = "az network bastion ssh --name ${module.bastion.bastion_name} --resource-group ${azurerm_resource_group.this.name} --target-resource-id ${module.validation_host.vm_id} --auth-type ssh-key --username ${local.client_admin_username} --ssh-key <path-to-private-key>"
    dns_validation  = "getent hosts ${local.cosmosdb_account_name}.documents.azure.com"
    nc_validation   = "nc -vz ${local.cosmosdb_account_name}.documents.azure.com 443"
    curl_validation = "curl -I ${local.cosmosdb_endpoint}"
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
