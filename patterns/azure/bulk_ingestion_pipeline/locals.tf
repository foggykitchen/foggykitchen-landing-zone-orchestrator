locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  functions    = local.config.functions
  data_layer   = local.config.data

  location            = nonsensitive(local.cloud.location)
  subscription_id     = nonsensitive(try(local.cloud.subscription_id, null))
  tenant_id           = nonsensitive(try(local.cloud.tenant_id, null))
  my_public_ip        = nonsensitive(try(local.cloud.my_public_ip, null))
  resource_group_name = nonsensitive(try(local.cloud.resource_group.name, "rg-${local.project_name}"))
  tags                = nonsensitive(merge(try(local.landing_zone.default_tags, {}), try(local.landing_zone.tags, {})))

  project_name = nonsensitive(try(local.landing_zone.name, "fk-azure-bulk-ingestion-pipeline-dev"))

  network = try(local.architecture.network, {})

  vnet_name              = nonsensitive(try(local.network.vnet.name, "vnet-${local.project_name}"))
  vnet_cidr              = nonsensitive(try(local.network.vnet.cidr, "10.180.0.0/16"))
  functions_subnet_name  = nonsensitive(try(local.network.functions_subnet.name, "snet-${local.project_name}-functions"))
  functions_subnet_cidr  = nonsensitive(try(local.network.functions_subnet.cidr, "10.180.20.0/24"))
  postgresql_subnet_name = nonsensitive(try(local.network.postgresql_subnet.name, "snet-${local.project_name}-postgresql"))
  postgresql_subnet_cidr = nonsensitive(try(local.network.postgresql_subnet.cidr, "10.180.30.0/24"))
  private_dns_zone_name  = nonsensitive(try(local.data_layer.postgresql.private_dns_zone_name, "${local.project_name}.postgres.database.azure.com"))

  source_path = nonsensitive(local.functions.source_path)

  function_app           = try(local.functions.app, {})
  function_app_name      = nonsensitive(try(local.function_app.name, "func-${local.project_name}"))
  function_plan_name     = nonsensitive(try(local.function_app.service_plan_name, "plan-${local.project_name}"))
  function_sku_name      = nonsensitive(try(local.function_app.sku, "EP1"))
  function_runtime_stack = nonsensitive(try(local.function_app.runtime_stack, { language = "python", version = "3.12" }))
  function_content_share = nonsensitive(try(local.function_app.content_share_name, replace("${local.project_name}content", "-", "")))
  function_debug_mode    = nonsensitive(try(local.function_app.debug_mode, true))

  identity_name = nonsensitive(try(local.functions.identity.name, "id-${local.project_name}-functions"))

  api                 = try(local.functions.api, {})
  api_management_name = nonsensitive(try(local.api.name, "apim-${local.project_name}"))
  api_name            = nonsensitive(try(local.api.api_name, "bulk-ingestion-data"))
  api_display_name    = nonsensitive(try(local.api.display_name, "Bulk Ingestion Data API"))
  api_path_prefix     = nonsensitive(try(local.api.path_prefix, "v1"))
  api_validator_name  = nonsensitive(try(local.api.validator_route_name, "fnvalidator"))
  api_validator_path  = nonsensitive(try(local.api.validator_route_path, "/validate"))
  api_publisher_name  = nonsensitive(local.api.publisher_name)
  api_publisher_email = nonsensitive(local.api.publisher_email)

  runtime        = try(local.functions.runtime, {})
  bulkload_name  = nonsensitive(try(local.runtime.bulkload_name, "fnbulkload"))
  collector_name = nonsensitive(try(local.runtime.collector_name, "fncollector"))
  validator_name = nonsensitive(try(local.runtime.validator_name, "fnvalidator"))

  storage                  = try(local.data_layer.storage, {})
  storage_account_name     = nonsensitive(local.storage.account_name)
  storage_container_name   = nonsensitive(try(local.storage.container_name, "incoming"))
  storage_allowed_ip_rules = local.my_public_ip == null ? [] : [local.my_public_ip]
  event_grid               = try(local.functions.event_grid, {})
  event_grid_topic_name    = nonsensitive(try(local.event_grid.system_topic_name, "${local.project_name}-storage-events"))
  event_grid_sub_name      = nonsensitive(try(local.event_grid.event_subscription_name, "blob-created-to-fnbulkload"))
  event_hub                = try(local.functions.event_hub, {})
  event_hub_namespace_name = nonsensitive(try(local.event_hub.namespace_name, "evhns-${local.project_name}"))
  event_hub_name           = nonsensitive(try(local.event_hub.event_hub_name, "ingestion"))
  event_hub_sku            = nonsensitive(try(local.event_hub.sku, "Standard"))
  event_hub_capacity       = nonsensitive(try(local.event_hub.capacity, 1))
  event_hub_partitions     = nonsensitive(try(local.event_hub.partition_count, 2))
  event_hub_retention_days = nonsensitive(try(local.event_hub.message_retention_in_days, 1))

  postgresql                  = try(local.data_layer.postgresql, {})
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
}
