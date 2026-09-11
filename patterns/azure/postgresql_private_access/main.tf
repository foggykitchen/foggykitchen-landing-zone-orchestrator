resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "terraform_data" "scope_guardrails" {
  input = local.private_access_mode

  lifecycle {
    precondition {
      condition     = local.private_access_mode == "delegated_subnet"
      error_message = "postgresql_private_access currently supports only private_access.mode = \"delegated_subnet\"."
    }

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

module "vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = local.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.vnet_cidr]

  subnets = {
    (local.client_subnet_name) = {
      address_prefixes = [local.client_subnet_cidr]
    }

    (local.bastion_subnet_name) = {
      address_prefixes = [local.bastion_subnet_cidr]
    }

    (local.database_subnet_name) = {
      address_prefixes = [local.database_subnet_cidr]
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

module "private_dns" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-private-dns.git?ref=v1.0.0"

  resource_group_name    = azurerm_resource_group.this.name
  private_dns_zone_names = [local.private_dns_zone_name]
  vnet_links             = { "${local.project_name}-vnet-link" = { vnet_id = module.vnet.vnet_id, registration_enabled = false } }
  tags                   = local.tags
}

module "database_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.0"

  name                = "${local.project_name}-database-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  rules = [
    {
      name                       = "allow-ssh-from-operator"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = local.bastion_subnet_cidr
      destination_address_prefix = local.client_subnet_cidr
      description                = "Allow SSH from Azure Bastion to the validation host subnet."
    },
    {
      name                       = "allow-postgresql-from-client-subnet"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = local.client_subnet_cidr
      destination_address_prefix = local.database_subnet_cidr
      description                = "Allow PostgreSQL access from the validation host subnet to the delegated database subnet."
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
      name                       = "allow-internet-egress-for-validation-host-bootstrap"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = local.client_subnet_cidr
      destination_address_prefix = "Internet"
      description                = "Allow package installation on the validation host during cloud-init."
    }
  ]

  subnet_associations = {
    client = {
      subnet_id = module.vnet.subnet_ids[local.client_subnet_name]
    }
    database = {
      subnet_id = module.vnet.subnet_ids[local.database_subnet_name]
    }
  }

  tags = local.tags
}

module "bastion" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-bastion.git?ref=v1.0.0"

  name                = "${local.project_name}-bastion"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  bastion_subnet_id   = module.vnet.subnet_ids[local.bastion_subnet_name]
  create_public_ip    = true
  sku                 = "Standard"
  tunneling_enabled   = true
  ip_connect_enabled  = true
  tags                = local.tags
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

  delegated_subnet_id           = module.vnet.subnet_ids[local.database_subnet_name]
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
    module.database_nsg,
    terraform_data.scope_guardrails
  ]
}

module "validation_host" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.3.5"

  name                = local.client_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  deployment_mode = "vm"
  subnet_id       = module.vnet.subnet_ids[local.client_subnet_name]

  admin_username    = local.client_admin_username
  ssh_public_key    = local.client_ssh_authorized_keys[0]
  vm_size           = local.client_shape
  attach_nsg_to_nic = false
  custom_data       = local.client_custom_data

  image_reference = {
    publisher = try(local.client.image.publisher, "Canonical")
    offer     = try(local.client.image.offer, "ubuntu-24_04-lts")
    sku       = try(local.client.image.sku, "server")
    version   = try(local.client.image.version, "latest")
  }

  tags = merge(local.tags, { workload = "postgresql-validation" })
}
