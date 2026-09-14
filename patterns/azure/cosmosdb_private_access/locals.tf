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

  project_name = nonsensitive(try(local.landing_zone.name, "fk-azure-cosmosdb-private-access-dev"))

  network  = try(local.architecture.network, {})
  access   = try(local.architecture.private_access, {})
  client   = try(local.workload.client, {})
  cosmosdb = try(local.data_layer.cosmosdb, {})

  private_access_mode = nonsensitive(try(local.access.mode, "private_endpoint"))

  vnet_name                    = nonsensitive(try(local.network.vnet.name, "${local.project_name}-vnet"))
  vnet_cidr                    = nonsensitive(try(local.network.vnet.cidr, "10.160.0.0/16"))
  client_subnet_name           = nonsensitive(try(local.network.client_subnet.name, "snet-${local.project_name}-client"))
  client_subnet_cidr           = nonsensitive(try(local.network.client_subnet.cidr, "10.160.10.0/24"))
  bastion_subnet_name          = "AzureBastionSubnet"
  bastion_subnet_cidr          = nonsensitive(try(local.network.bastion_subnet.cidr, "10.160.30.0/26"))
  private_endpoint_subnet_name = nonsensitive(try(local.network.private_endpoint_subnet.name, "snet-${local.project_name}-private-endpoint"))
  private_endpoint_subnet_cidr = nonsensitive(try(local.network.private_endpoint_subnet.cidr, "10.160.20.0/24"))
  private_dns_zone_name        = nonsensitive(try(local.cosmosdb.account.private_dns_zone_name, "privatelink.documents.azure.com"))

  client_name                = nonsensitive(try(local.client.name, "${local.project_name}-client"))
  client_shape               = nonsensitive(try(local.client.shape, "Standard_B1s"))
  client_admin_username      = nonsensitive(try(local.client.admin_username, "azureuser"))
  client_ssh_authorized_keys = nonsensitive(try(local.client.ssh_authorized_keys, []))
  client_cloud_init_override = nonsensitive(try(local.client.cloud_init_override, null))

  cosmosdb_account_name = nonsensitive(local.cosmosdb.account.name)
  cosmosdb_kind         = nonsensitive(try(local.cosmosdb.account.kind, "GlobalDocumentDB"))
  cosmosdb_database     = try(local.cosmosdb.sql_database, {})
  cosmosdb_container    = try(local.cosmosdb.sql_container, {})

  cosmosdb_database_name       = nonsensitive(try(local.cosmosdb_database.name, "foggydb"))
  cosmosdb_database_throughput = nonsensitive(try(local.cosmosdb_database.throughput, 400))

  cosmosdb_container_name                  = nonsensitive(try(local.cosmosdb_container.name, "items"))
  cosmosdb_container_partition_key_paths   = nonsensitive(try(local.cosmosdb_container.partition_key_paths, ["/partitionKey"]))
  cosmosdb_container_partition_key_version = nonsensitive(try(local.cosmosdb_container.partition_key_version, 2))

  cosmosdb_identity    = nonsensitive(try(local.cosmosdb.identity, null))
  cosmosdb_cmk         = nonsensitive(try(local.cosmosdb.cmk, null))
  cosmosdb_diagnostics = nonsensitive(try(local.cosmosdb.diagnostics, null))
  cosmosdb_rbac        = nonsensitive(try(local.cosmosdb.rbac, null))

  cosmosdb_endpoint = "https://${local.cosmosdb_account_name}.documents.azure.com:443/"

  default_client_custom_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/fk-cosmosdb-private/README.txt
        owner: root:root
        permissions: "0644"
        content: |
          FoggyKitchen Azure Cosmos DB Private Access validation host
          -----------------------------------------------------------
          Use this host to validate private Cosmos DB SQL API reachability.

          Suggested checks:
            getent hosts ${local.cosmosdb_account_name}.documents.azure.com
            nc -vz ${local.cosmosdb_account_name}.documents.azure.com 443
            curl -I https://${local.cosmosdb_account_name}.documents.azure.com:443/

    runcmd:
      - [ bash, -lc, "apt-get update || true" ]
      - [ bash, -lc, "DEBIAN_FRONTEND=noninteractive apt-get install -y netcat-openbsd dnsutils curl || true" ]
  EOT

  client_custom_data = base64encode(coalesce(local.client_cloud_init_override, local.default_client_custom_data))
}
