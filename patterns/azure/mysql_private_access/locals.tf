locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  workload     = try(local.config.workload, {})
  data_layer   = try(local.config.data, {})

  location            = nonsensitive(local.cloud.location)
  subscription_id     = nonsensitive(try(local.cloud.subscription_id, null))
  tenant_id           = nonsensitive(try(local.cloud.tenant_id, null))
  resource_group_name = nonsensitive(try(local.cloud.resource_group.name, "rg-${local.project_name}"))
  tags                = nonsensitive(merge(try(local.landing_zone.default_tags, {}), try(local.landing_zone.tags, {})))

  project_name = nonsensitive(try(local.landing_zone.name, "fk-azure-mysql-private-access-dev"))

  network = try(local.architecture.network, {})
  access  = try(local.architecture.private_access, {})
  client  = try(local.workload.client, {})
  mysql   = try(local.data_layer.mysql, {})

  private_access_mode = nonsensitive(try(local.access.mode, "delegated_subnet"))

  vnet_name             = nonsensitive(try(local.network.vnet.name, "${local.project_name}-vnet"))
  vnet_cidr             = nonsensitive(try(local.network.vnet.cidr, "10.150.0.0/16"))
  client_subnet_name    = nonsensitive(try(local.network.client_subnet.name, "snet-${local.project_name}-client"))
  client_subnet_cidr    = nonsensitive(try(local.network.client_subnet.cidr, "10.150.10.0/24"))
  bastion_subnet_name   = "AzureBastionSubnet"
  bastion_subnet_cidr   = nonsensitive(try(local.network.bastion_subnet.cidr, "10.150.30.0/26"))
  database_subnet_name  = nonsensitive(try(local.network.delegated_subnet.name, "snet-${local.project_name}-mysql"))
  database_subnet_cidr  = nonsensitive(try(local.network.delegated_subnet.cidr, "10.150.20.0/24"))
  private_dns_zone_name = nonsensitive(try(local.mysql.server.private_dns_zone_name, "${local.project_name}.mysql.database.azure.com"))

  client_name                = nonsensitive(try(local.client.name, "${local.project_name}-client"))
  client_shape               = nonsensitive(try(local.client.shape, "Standard_B1s"))
  client_admin_username      = nonsensitive(try(local.client.admin_username, "azureuser"))
  client_ssh_authorized_keys = nonsensitive(try(local.client.ssh_authorized_keys, []))
  client_cloud_init_override = nonsensitive(try(local.client.cloud_init_override, null))

  mysql_server_name      = nonsensitive(local.mysql.server.name)
  mysql_version          = nonsensitive(try(local.mysql.server.version, "8.0.21"))
  mysql_sku_name         = nonsensitive(try(local.mysql.server.sku, "GP_Standard_D2ds_v4"))
  mysql_storage          = nonsensitive(try(local.mysql.server.storage, { size_gb = 32 }))
  mysql_admin_login      = nonsensitive(try(local.mysql.server.admin_login, "mysqladmin"))
  mysql_admin_password   = local.mysql.server.admin_password
  mysql_database_name    = nonsensitive(local.mysql.database.name)
  mysql_database_charset = nonsensitive(try(local.mysql.database.charset, "utf8"))
  mysql_database_collate = nonsensitive(try(local.mysql.database.collation, "utf8_unicode_ci"))

  mysql_entra       = nonsensitive(try(local.mysql.entra, null))
  mysql_cmk         = nonsensitive(try(local.mysql.cmk, null))
  mysql_diagnostics = nonsensitive(try(local.mysql.diagnostics, null))

  default_client_custom_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/fk-mysql-private/README.txt
        owner: root:root
        permissions: "0644"
        content: |
          FoggyKitchen Azure MySQL Private Access validation host
          ------------------------------------------------------
          Use this host to validate private MySQL reachability.

          Suggested checks:
            getent hosts ${local.mysql_server_name}.mysql.database.azure.com
            nc -vz ${local.mysql_server_name}.mysql.database.azure.com 3306
            mysql --host=${local.mysql_server_name}.mysql.database.azure.com --port=3306 --user=${local.mysql_admin_login} --ssl-mode=REQUIRED --database=${local.mysql_database_name} --password

    runcmd:
      - [ bash, -lc, "apt-get update || true" ]
      - [ bash, -lc, "DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-client netcat-openbsd dnsutils || true" ]
  EOT

  client_custom_data = base64encode(coalesce(local.client_cloud_init_override, local.default_client_custom_data))
}
