output "adb_private_access" {
  value = {
    adb_database_id      = nonsensitive(module.adb.adb_database.adb_database_id)
    adb_display_name     = nonsensitive(local.adb_display_name)
    connection_urls      = nonsensitive(module.adb.adb_database.connection_urls)
    private_endpoint_ip  = nonsensitive(module.adb.adb_database.private_endpoint_ip)
    adb_subnet_id        = nonsensitive(module.vcn.subnet_ids["adb_private"])
    adb_nsg_id           = nonsensitive(module.adb_nsg.nsg_id)
    private_endpoint_dns = nonsensitive(try(module.adb.adb_database.connection_urls.low, null))
  }
}

output "validation_host" {
  value = {
    instance_id   = module.client_host.instance_id
    public_ip     = module.client_host.instance_public_ip
    private_ip    = module.client_host.instance_private_ip
    ssh_user      = "opc"
    subnet_id     = module.vcn.subnet_ids["client_public"]
    ssh_command   = "ssh opc@${module.client_host.instance_public_ip}"
    nc_validation = "nc -vz ${module.adb.adb_database.private_endpoint_ip} 1522"
  }
}

output "network" {
  value = {
    vcn_id             = nonsensitive(module.vcn.vcn_id)
    client_subnet_id   = nonsensitive(module.vcn.subnet_ids["client_public"])
    adb_subnet_id      = nonsensitive(module.vcn.subnet_ids["adb_private"])
    client_subnet_cidr = nonsensitive(local.client_subnet_cidr)
    adb_subnet_cidr    = nonsensitive(local.adb_subnet_cidr)
  }
}

output "adb_wallet" {
  sensitive = true
  value = {
    password = module.adb.adb_database.adb_wallet_password
    content  = module.adb.adb_database.adb_wallet_content
  }
}
