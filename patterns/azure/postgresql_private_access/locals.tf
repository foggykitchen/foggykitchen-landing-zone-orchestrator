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

  project_name = nonsensitive(try(local.landing_zone.name, "fk-azure-pg-private-access-dev"))

  network    = try(local.architecture.network, {})
  access     = try(local.architecture.private_access, {})
  client     = try(local.workload.client, {})
  postgresql = try(local.data_layer.postgresql, {})

  private_access_mode = nonsensitive(try(local.access.mode, "delegated_subnet"))
  is_delegated_subnet = local.private_access_mode == "delegated_subnet"
  is_private_endpoint = local.private_access_mode == "private_endpoint"

  vnet_name                    = nonsensitive(try(local.network.vnet.name, "${local.project_name}-vnet"))
  vnet_cidr                    = nonsensitive(try(local.network.vnet.cidr, "10.130.0.0/16"))
  client_subnet_name           = nonsensitive(try(local.network.client_subnet.name, "snet-${local.project_name}-client"))
  client_subnet_cidr           = nonsensitive(try(local.network.client_subnet.cidr, "10.130.10.0/24"))
  bastion_subnet_name          = "AzureBastionSubnet"
  bastion_subnet_cidr          = nonsensitive(try(local.network.bastion_subnet.cidr, "10.130.30.0/26"))
  database_subnet_name         = nonsensitive(try(local.network.delegated_subnet.name, "snet-${local.project_name}-postgresql"))
  database_subnet_cidr         = nonsensitive(try(local.network.delegated_subnet.cidr, "10.130.20.0/24"))
  private_endpoint_subnet_name = nonsensitive(try(local.network.private_endpoint_subnet.name, "snet-${local.project_name}-private-endpoint"))
  private_endpoint_subnet_cidr = nonsensitive(try(local.network.private_endpoint_subnet.cidr, "10.130.20.0/24"))
  private_dns_zone_name        = nonsensitive(try(local.postgresql.private_dns_zone_name, local.is_private_endpoint ? "privatelink.postgres.database.azure.com" : "${local.project_name}.postgres.database.azure.com"))

  client_name                = nonsensitive(try(local.client.name, "${local.project_name}-client"))
  client_shape               = nonsensitive(try(local.client.shape, "Standard_B1s"))
  client_admin_username      = nonsensitive(try(local.client.admin_username, "azureuser"))
  client_ssh_authorized_keys = nonsensitive(try(local.client.ssh_authorized_keys, []))
  client_cloud_init_override = nonsensitive(try(local.client.cloud_init_override, null))

  postgresql_server_name      = nonsensitive(local.postgresql.server.name)
  postgresql_version          = nonsensitive(try(local.postgresql.server.version, "16"))
  postgresql_sku_name         = nonsensitive(try(local.postgresql.server.sku, "GP_Standard_D2s_v3"))
  postgresql_storage_mb       = nonsensitive(try(local.postgresql.server.storage_mb, 32768))
  postgresql_admin_login      = nonsensitive(try(local.postgresql.server.admin_login, "pgadmin"))
  postgresql_admin_password   = local.postgresql.server.admin_password
  postgresql_database_name    = nonsensitive(local.postgresql.database.name)
  postgresql_database_charset = nonsensitive(try(local.postgresql.database.charset, "UTF8"))
  postgresql_database_collate = nonsensitive(try(local.postgresql.database.collation, "en_US.utf8"))

  postgresql_entra       = nonsensitive(try(local.postgresql.entra, null))
  postgresql_cmk         = nonsensitive(try(local.postgresql.cmk, null))
  postgresql_diagnostics = nonsensitive(try(local.postgresql.diagnostics, null))

  default_client_custom_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/fk-postgresql-private/README.txt
        owner: root:root
        permissions: "0644"
        content: |
          FoggyKitchen Azure PostgreSQL Private Access validation host
          -----------------------------------------------------------
          Use this host to validate private PostgreSQL reachability.

          Suggested checks:
            getent hosts ${local.postgresql_server_name}
            nc -vz ${local.postgresql_server_name} 5432
            psql "host=${local.postgresql_server_name} port=5432 dbname=${local.postgresql_database_name} user=${local.postgresql_admin_login} sslmode=require"

    runcmd:
      - [ bash, -lc, "apt-get update || true" ]
      - [ bash, -lc, "DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client netcat-openbsd dnsutils || true" ]
  EOT

  client_custom_data = base64encode(coalesce(local.client_cloud_init_override, local.default_client_custom_data))
}
