output "basedb_private_access" {
  value = {
    db_system_id       = module.basedb.db_system_id
    database_id        = module.basedb.database_id
    private_ips        = module.basedb.private_ips
    connection_strings = module.basedb.connection_strings
    db_subnet_id       = module.vcn.subnet_ids["db_private"]
    db_nsg_id          = module.db_nsg.nsg_id
  }
}
output "bastion" {
  value = {
    bastion_id          = module.bastion.bastion_id
    session_id          = module.bastion.session_id
    session_ssh_command = module.bastion.session_ssh_command
  }
}
output "validation_host" {
  value = {
    instance_id   = module.client_host.instance_id
    private_ip    = module.client_host.instance_private_ip
    nc_validation = "nc -vz ${module.basedb.private_ips[0]} 1521"
  }
}
output "network" {
  value = {
    vcn_id           = module.vcn.vcn_id
    client_subnet_id = module.vcn.subnet_ids["client_private"]
    db_subnet_id     = module.vcn.subnet_ids["db_private"]
    cidrs            = { vcn = local.vcn_cidr, client = local.client_subnet_cidr, db = local.db_subnet_cidr }
  }
}
