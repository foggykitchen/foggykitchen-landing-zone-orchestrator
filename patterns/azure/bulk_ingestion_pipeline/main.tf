resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "terraform_data" "scope_guardrails" {
  input = local.project_name

  lifecycle {
    precondition {
      condition     = local.postgresql_entra == null
      error_message = "data.postgresql.entra is reserved for a later secure variant and is not supported by this basic pattern yet."
    }

    precondition {
      condition     = local.postgresql_cmk == null
      error_message = "data.postgresql.cmk is reserved for a later secure variant and is not supported by this basic pattern yet."
    }

    precondition {
      condition     = local.postgresql_diagnostics == null
      error_message = "data.postgresql.diagnostics is reserved for a later secure variant and is not supported by this basic pattern yet."
    }
  }
}

moved {
  from = module.storage.azurerm_storage_account_network_rules.this[0]
  to   = azurerm_storage_account_network_rules.function_host
}

data "archive_file" "function_package" {
  type        = "zip"
  source_dir  = local.source_path
  output_path = "${path.module}/function.zip"
}

module "vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = local.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.vnet_cidr]

  subnets = {
    (local.functions_subnet_name) = {
      address_prefixes  = [local.functions_subnet_cidr]
      service_endpoints = ["Microsoft.Storage"]
      delegations = [
        {
          name = "functions-integration"
          service_delegation = {
            name    = "Microsoft.Web/serverFarms"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      ]
    }

    (local.postgresql_subnet_name) = {
      address_prefixes = [local.postgresql_subnet_cidr]
      delegations = [
        {
          name = "postgresql-flexible-server-delegation"
          service_delegation = {
            name    = "Microsoft.DBforPostgreSQL/flexibleServers"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      ]
    }
  }

  tags = local.tags
}

module "functions_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.0"

  name                = "${local.project_name}-functions-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  rules = [
    {
      name                       = "deny-internet-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Deny direct Internet inbound traffic to the Functions integration subnet."
    },
    {
      name                       = "allow-vnet-egress"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow VNet-local outbound traffic."
    },
    {
      name                       = "allow-azure-platform-egress"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
      description                = "Allow Functions runtime access to Azure platform services."
    }
  ]

  subnet_associations = {
    functions = {
      subnet_id = module.vnet.subnet_ids[local.functions_subnet_name]
    }
  }

  tags = local.tags
}

module "private_dns" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-private-dns.git?ref=v1.0.0"

  resource_group_name    = azurerm_resource_group.this.name
  private_dns_zone_names = [local.private_dns_zone_name]
  vnet_links             = { "${local.project_name}-vnet-link" = { vnet_id = module.vnet.vnet_id, registration_enabled = false } }
  tags                   = local.tags
}

module "storage" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-storage.git?ref=v1.1.0"

  name                          = local.storage_account_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  public_network_access_enabled = true
  create_file_shares            = true
  file_shares = {
    (local.function_content_share) = {
      quota_gb = 1
    }
  }
  create_containers = true
  containers = {
    (local.storage_container_name) = {
      access_type = "private"
    }
  }
  tags = local.tags
}

module "identity" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-managed-identity.git?ref=v0.1.0"

  name                = local.identity_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "event_hub" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-event-hub.git?ref=v0.1.0"

  name                = local.event_hub_namespace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = local.event_hub_sku
  capacity            = local.event_hub_capacity
  event_hubs = {
    ingestion = {
      name                      = local.event_hub_name
      partition_count           = local.event_hub_partitions
      message_retention_in_days = local.event_hub_retention_days
    }
  }
  tags = local.tags
}

module "event_hub_sender_rbac" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-rbac.git?ref=v0.1.2"

  scope                = module.event_hub.event_hub_ids["ingestion"]
  principal_id         = module.identity.principal_id
  role_definition_name = "Azure Event Hubs Data Sender"
}

module "event_hub_receiver_rbac" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-rbac.git?ref=v0.1.2"

  scope                = module.event_hub.event_hub_ids["ingestion"]
  principal_id         = module.identity.principal_id
  role_definition_name = "Azure Event Hubs Data Receiver"
}

module "storage_blob_reader_rbac" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-rbac.git?ref=v0.1.2"

  scope                = module.storage.storage_account_id
  principal_id         = module.identity.principal_id
  role_definition_name = "Storage Blob Data Reader"
}

module "postgresql" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-pg.git?ref=v1.0.1"

  name                = local.postgresql_server_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  postgresql_version     = local.postgresql_version
  administrator_login    = local.postgresql_admin_login
  administrator_password = local.postgresql_admin_password
  sku_name               = local.postgresql_sku_name
  storage_mb             = local.postgresql_storage_mb

  delegated_subnet_id           = module.vnet.subnet_ids[local.postgresql_subnet_name]
  private_dns_zone_id           = module.private_dns.private_dns_zone_ids[local.private_dns_zone_name]
  public_network_access_enabled = false
  firewall_rules                = {}

  databases = {
    (local.postgresql_database_name) = {
      charset   = local.postgresql_database_charset
      collation = local.postgresql_database_collate
    }
  }

  tags = local.tags

  depends_on = [
    module.private_dns,
    terraform_data.scope_guardrails
  ]
}

module "function_app" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-function.git?ref=v0.1.0"

  name                = local.function_app_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  service_plan_name = local.function_plan_name
  sku_name          = local.function_sku_name

  storage_account_name       = module.storage.storage_account_name
  storage_account_access_key = module.storage.primary_access_key
  infrastructure_subnet_id   = module.vnet.subnet_ids[local.functions_subnet_name]
  vnet_route_all_enabled     = true
  vnet_content_share_enabled = true

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.identity.id]
  }

  runtime_stack   = local.function_runtime_stack
  zip_deploy_file = data.archive_file.function_package.output_path

  app_settings = {
    AZURE_CLIENT_ID                              = module.identity.client_id
    AzureWebJobsFeatureFlags                     = "EnableWorkerIndexing"
    DEBUG_MODE                                   = tostring(local.function_debug_mode)
    ENABLE_ORYX_BUILD                            = "true"
    FK_FUNCTION_PACKAGE_SHA                      = data.archive_file.function_package.output_sha256
    SCM_DO_BUILD_DURING_DEPLOYMENT               = "true"
    WEBSITE_CONTENTOVERVNET                      = "1"
    WEBSITE_CONTENTSHARE                         = local.function_content_share
    EVENTHUB_CONNECTION__fullyQualifiedNamespace = "${module.event_hub.namespace_name}.servicebus.windows.net"
    EVENTHUB_CONNECTION__clientId                = module.identity.client_id
    EVENTHUB_NAME                                = local.event_hub_name
    INGESTION_STORAGE_CONTAINER                  = local.storage_container_name
    POSTGRES_HOST                                = module.postgresql.fqdn
    POSTGRES_PORT                                = "5432"
    POSTGRES_DATABASE                            = local.postgresql_database_name
    POSTGRES_USER                                = local.postgresql_admin_login
    POSTGRES_PASSWORD                            = local.postgresql_admin_password
    POSTGRES_SSLMODE                             = "require"
  }

  tags = local.tags

  depends_on = [
    module.event_hub_sender_rbac,
    module.event_hub_receiver_rbac,
    module.storage_blob_reader_rbac,
    module.postgresql,
    module.functions_nsg
  ]
}

resource "azurerm_storage_account_network_rules" "function_host" {
  storage_account_id = module.storage.storage_account_id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  ip_rules                   = local.storage_allowed_ip_rules
  virtual_network_subnet_ids = [module.vnet.subnet_ids[local.functions_subnet_name]]

  depends_on = [module.function_app]
}

resource "azapi_resource_action" "function_triggers_sync" {
  type        = "Microsoft.Web/sites@2023-12-01"
  resource_id = module.function_app.id
  action      = "syncfunctiontriggers"
  method      = "POST"

  depends_on = [
    module.function_app
  ]
}

module "api_management" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-api-management.git?ref=v0.1.0"

  name                  = local.api_management_name
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  publisher_name        = local.api_publisher_name
  publisher_email       = local.api_publisher_email
  api_name              = local.api_name
  api_display_name      = local.api_display_name
  path_prefix           = local.api_path_prefix
  subscription_required = false

  routes = [
    {
      name    = local.api_validator_name
      path    = local.api_validator_path
      methods = ["GET"]
      backend = {
        type        = "FUNCTION_BACKEND"
        function_id = "${module.function_app.id}/functions/${local.validator_name}"
      }
    }
  ]

  tags = local.tags
}

module "event_grid" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-event-grid.git?ref=v0.1.0"

  system_topic_name       = local.event_grid_topic_name
  event_subscription_name = local.event_grid_sub_name
  resource_group_name     = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  source_resource_id      = module.storage.storage_account_id
  topic_type              = "Microsoft.Storage.StorageAccounts"
  included_event_types    = ["Microsoft.Storage.BlobCreated"]

  subject_filter = {
    subject_begins_with = "/blobServices/default/containers/${local.storage_container_name}/"
  }

  endpoint = {
    azure_function = {
      function_id = "${module.function_app.id}/functions/${local.bulkload_name}"
    }
  }

  tags = local.tags

  depends_on = [
    module.function_app
  ]
}
