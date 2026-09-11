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

  project_name = nonsensitive(try(local.landing_zone.name, "fk-azure-sql-private-access-dev"))

  network = try(local.architecture.network, {})
  access  = try(local.architecture.private_access, {})
  client  = try(local.workload.client, {})
  sql     = try(local.data_layer.sql, {})

  private_access_mode = nonsensitive(try(local.access.mode, "private_endpoint"))

  vnet_name                    = nonsensitive(try(local.network.vnet.name, "${local.project_name}-vnet"))
  vnet_cidr                    = nonsensitive(try(local.network.vnet.cidr, "10.140.0.0/16"))
  client_subnet_name           = nonsensitive(try(local.network.client_subnet.name, "snet-${local.project_name}-client"))
  client_subnet_cidr           = nonsensitive(try(local.network.client_subnet.cidr, "10.140.10.0/24"))
  bastion_subnet_name          = "AzureBastionSubnet"
  bastion_subnet_cidr          = nonsensitive(try(local.network.bastion_subnet.cidr, "10.140.30.0/26"))
  private_endpoint_subnet_name = nonsensitive(try(local.network.private_endpoint_subnet.name, "snet-${local.project_name}-private-endpoint"))
  private_endpoint_subnet_cidr = nonsensitive(try(local.network.private_endpoint_subnet.cidr, "10.140.20.0/24"))
  private_dns_zone_name        = nonsensitive(try(local.sql.server.private_dns_zone_name, "privatelink.database.windows.net"))

  client_name                = nonsensitive(try(local.client.name, "${local.project_name}-client"))
  client_shape               = nonsensitive(try(local.client.shape, "Standard_B1s"))
  client_admin_username      = nonsensitive(try(local.client.admin_username, "azureuser"))
  client_ssh_authorized_keys = nonsensitive(try(local.client.ssh_authorized_keys, []))
  client_cloud_init_override = nonsensitive(try(local.client.cloud_init_override, null))

  sql_server_name       = nonsensitive(local.sql.server.name)
  sql_server_version    = nonsensitive(try(local.sql.server.version, "12.0"))
  sql_admin_login       = nonsensitive(try(local.sql.server.admin_login, "sqladmin"))
  sql_admin_password    = local.sql.server.admin_password
  sql_database_name     = nonsensitive(local.sql.database.name)
  sql_database_sku_name = nonsensitive(try(local.sql.database.sku_name, "S0"))
  sql_database_size_gb  = nonsensitive(try(local.sql.database.max_size_gb, 2))

  sql_entra       = nonsensitive(try(local.sql.entra, null))
  sql_cmk         = nonsensitive(try(local.sql.cmk, null))
  sql_diagnostics = nonsensitive(try(local.sql.diagnostics, null))

  default_client_custom_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/fk-sql-private/README.txt
        owner: root:root
        permissions: "0644"
        content: |
          FoggyKitchen Azure SQL Private Access validation host
          ----------------------------------------------------
          Use this host to validate private Azure SQL reachability.

          Suggested checks:
            getent hosts ${local.sql_server_name}.database.windows.net
            nc -vz ${local.sql_server_name}.database.windows.net 1433

    runcmd:
      - [ bash, -lc, "apt-get update || true" ]
      - [ bash, -lc, "DEBIAN_FRONTEND=noninteractive apt-get install -y netcat-openbsd dnsutils || true" ]
  EOT

  client_custom_data = base64encode(coalesce(local.client_cloud_init_override, local.default_client_custom_data))
}
