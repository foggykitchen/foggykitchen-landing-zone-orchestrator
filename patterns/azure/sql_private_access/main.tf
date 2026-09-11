resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "terraform_data" "scope_guardrails" {
  input = local.private_access_mode

  lifecycle {
    precondition {
      condition     = local.private_access_mode == "private_endpoint"
      error_message = "sql_private_access currently supports only private_access.mode = \"private_endpoint\"."
    }

    precondition {
      condition     = local.sql_entra == null
      error_message = "data.sql.entra is reserved for a later secure variant and is not supported by this pattern yet."
    }

    precondition {
      condition     = local.sql_cmk == null
      error_message = "data.sql.cmk is reserved for a later secure variant and is not supported by this pattern yet."
    }

    precondition {
      condition     = local.sql_diagnostics == null
      error_message = "data.sql.diagnostics is reserved for a later secure variant and is not supported by this pattern yet."
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

    (local.private_endpoint_subnet_name) = {
      address_prefixes                  = [local.private_endpoint_subnet_cidr]
      private_endpoint_network_policies = "Disabled"
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
      name                       = "allow-ssh-from-bastion"
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
      name                       = "allow-sql-from-client-subnet"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = local.client_subnet_cidr
      destination_address_prefix = local.private_endpoint_subnet_cidr
      description                = "Allow Azure SQL access from the validation host subnet to the Private Endpoint subnet."
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
    private_endpoint = {
      subnet_id = module.vnet.subnet_ids[local.private_endpoint_subnet_name]
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

module "sql" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-sql.git?ref=v1.0.0"

  name                = local.sql_server_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sql_server_version            = local.sql_server_version
  administrator_login           = local.sql_admin_login
  administrator_password        = local.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  firewall_rules                = {}

  databases = {
    (local.sql_database_name) = {
      sku_name    = local.sql_database_sku_name
      max_size_gb = local.sql_database_size_gb
    }
  }

  tags = local.tags

  depends_on = [
    terraform_data.scope_guardrails
  ]
}

module "sql_private_endpoint" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-private-endpoint.git?ref=v1.0.0"

  name                = "${local.project_name}-sql-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  subnet_id                      = module.vnet.subnet_ids[local.private_endpoint_subnet_name]
  private_connection_resource_id = module.sql.id
  subresource_names              = ["sqlServer"]
  private_dns_zone_group_name    = "default"
  private_dns_zone_ids           = [module.private_dns.private_dns_zone_ids[local.private_dns_zone_name]]
  tags                           = local.tags

  depends_on = [
    module.database_nsg,
    module.private_dns
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

  tags = merge(local.tags, { workload = "sql-validation" })
}
