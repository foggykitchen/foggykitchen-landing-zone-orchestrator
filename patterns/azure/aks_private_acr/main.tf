resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "terraform_data" "scope_guardrails" {
  input = local.aks_name

  lifecycle {
    precondition {
      condition     = local.aks_private_cluster_enabled == true
      error_message = "aks_private_acr supports only private AKS clusters. Set data.aks.cluster.private_cluster_enabled to true or omit it."
    }

    precondition {
      condition     = local.aks_network_plugin == "azure"
      error_message = "aks_private_acr supports only AKS Azure CNI with network_plugin = \"azure\"."
    }

    precondition {
      condition     = local.aks_outbound_type == "userDefinedRouting"
      error_message = "aks_private_acr supports outbound_type = \"userDefinedRouting\" with an empty route table associated to the AKS node subnet and NAT Gateway egress."
    }

    precondition {
      condition     = length(local.jump_ssh_authorized_keys) == 1
      error_message = "workload.jump.ssh_authorized_keys must contain exactly one SSH public key."
    }

    precondition {
      condition     = local.aks_acr != null && local.acr_name != null
      error_message = "aks_private_acr requires data.aks.acr.name."
    }

    precondition {
      condition     = local.acr_sku == "Premium"
      error_message = "aks_private_acr requires Azure Container Registry sku = \"Premium\" for Private Endpoint support."
    }

    precondition {
      condition     = local.acr_public_access == false
      error_message = "aks_private_acr requires data.aks.acr.public_network_access_enabled = false or omitted."
    }

    precondition {
      condition     = local.aks_diagnostics == null
      error_message = "data.aks.diagnostics is reserved for a later blueprint-tier AKS pattern and is not supported by aks_private_acr."
    }

    precondition {
      condition     = length(local.aks_additional_pool) == 0
      error_message = "data.aks.additional_node_pools is reserved for a later blueprint-tier AKS pattern and is not supported by aks_private_acr."
    }

    precondition {
      condition     = local.aks_cmk == null
      error_message = "data.aks.cmk is reserved for a later blueprint-tier AKS pattern and is not supported by aks_private_acr."
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
    (local.node_subnet_name) = {
      address_prefixes = [local.node_subnet_cidr]
    }

    (local.jump_subnet_name) = {
      address_prefixes = [local.jump_subnet_cidr]
    }

    (local.pe_subnet_name) = {
      address_prefixes                  = [local.pe_subnet_cidr]
      private_endpoint_network_policies = "Disabled"
    }

    (local.bastion_subnet_name) = {
      address_prefixes = [local.bastion_subnet_cidr]
    }
  }

  tags = local.tags
}

module "node_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.0"

  name                = "${local.project_name}-node-nsg"
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
      destination_address_prefix = local.node_subnet_cidr
      description                = "Deny direct Internet-originated inbound traffic to the AKS node subnet."
    },
    {
      name                       = "allow-internet-egress"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = local.node_subnet_cidr
      destination_address_prefix = "Internet"
      description                = "Allow outbound traffic through the subnet-associated NAT Gateway."
    }
  ]

  subnet_associations = {
    nodes = {
      subnet_id = module.vnet.subnet_ids[local.node_subnet_name]
    }
  }

  tags = local.tags
}

module "jump_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.0"

  name                = "${local.project_name}-jump-nsg"
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
      destination_address_prefix = local.jump_subnet_cidr
      description                = "Allow SSH from Azure Bastion to the private jump subnet."
    },
    {
      name                       = "allow-rdp-from-bastion"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = local.bastion_subnet_cidr
      destination_address_prefix = local.jump_subnet_cidr
      description                = "Allow RDP from Azure Bastion if Windows jump hosts are added later."
    },
    {
      name                       = "deny-internet-inbound"
      priority                   = 400
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = local.jump_subnet_cidr
      description                = "Deny direct Internet-originated inbound traffic to the jump subnet."
    },
    {
      name                       = "allow-internet-egress"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = local.jump_subnet_cidr
      destination_address_prefix = "Internet"
      description                = "Allow outbound traffic through the subnet-associated NAT Gateway."
    }
  ]

  subnet_associations = {
    jump = {
      subnet_id = module.vnet.subnet_ids[local.jump_subnet_name]
    }
  }

  tags = local.tags
}

module "routing" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-routing.git?ref=v0.4.2"

  resource_group_name = azurerm_resource_group.this.name

  route_tables = {
    (local.route_table_name) = {
      location   = azurerm_resource_group.this.location
      routes     = []
      subnet_ids = [module.vnet.subnet_ids[local.node_subnet_name]]
    }
  }

  tags = local.tags
}

module "private_dns" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-private-dns.git?ref=v1.0.0"

  resource_group_name    = azurerm_resource_group.this.name
  private_dns_zone_names = [local.acr_private_dns_zone_name]
  vnet_links = {
    aks = {
      vnet_id              = module.vnet.vnet_id
      registration_enabled = false
    }
  }

  tags = local.tags
}

module "acr" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-acr.git?ref=v0.2.0"

  acr_name                      = local.acr_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = local.acr_sku
  admin_enabled                 = local.acr_admin_enabled
  public_network_access_enabled = false
  tags                          = local.tags
}

module "acr_private_endpoint" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-private-endpoint.git?ref=v1.0.0"

  name                           = local.acr_private_endpoint_name
  location                       = azurerm_resource_group.this.location
  resource_group_name            = azurerm_resource_group.this.name
  subnet_id                      = module.vnet.subnet_ids[local.pe_subnet_name]
  private_connection_resource_id = module.acr.acr_id
  subresource_names              = ["registry"]
  private_dns_zone_group_name    = "default"
  private_dns_zone_ids           = [module.private_dns.private_dns_zone_ids[local.acr_private_dns_zone_name]]
  tags                           = local.tags

  depends_on = [
    module.private_dns,
    module.acr
  ]
}

module "nat_gateway_public_ip" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-public-ip.git?ref=v1.0.0"

  name                = local.nat_gateway_public_ip_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

module "nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.0"

  name                = local.nat_gateway_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  create_public_ip = false
  public_ip_id     = module.nat_gateway_public_ip.id

  subnet_associations = {
    aks_nodes = {
      subnet_id = module.vnet.subnet_ids[local.node_subnet_name]
    }
    jump = {
      subnet_id = module.vnet.subnet_ids[local.jump_subnet_name]
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

module "aks" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-aks.git?ref=v2.0.0"

  name                = local.aks_name
  location            = azurerm_resource_group.this.location
  create_rg           = false
  resource_group_name = azurerm_resource_group.this.name

  create_networking = false
  vnet_id           = module.vnet.vnet_id
  subnet_id         = module.vnet.subnet_ids[local.node_subnet_name]

  kubernetes_version      = local.aks_kubernetes_version
  network_plugin          = local.aks_network_plugin
  network_policy          = local.aks_network_policy
  service_cidr            = local.aks_service_cidr
  dns_service_ip          = local.aks_dns_service_ip
  private_cluster_enabled = true
  outbound_type           = local.aks_outbound_type

  default_node_count     = local.aks_default_node_count
  default_node_vm_size   = local.aks_default_node_vm_size
  default_node_subnet_id = module.vnet.subnet_ids[local.node_subnet_name]

  additional_node_pools = []
  acr_id                = null
  create_acr            = false
  enable_log_analytics  = false
  create_law            = false

  tags = local.tags

  depends_on = [
    module.node_nsg,
    module.jump_nsg,
    module.routing,
    module.nat_gateway,
    module.acr_private_endpoint,
    terraform_data.scope_guardrails
  ]
}

data "azurerm_role_definition" "acr_pull" {
  name  = "AcrPull"
  scope = module.acr.acr_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope              = module.acr.acr_id
  role_definition_id = data.azurerm_role_definition.acr_pull.role_definition_id
  principal_id       = module.aks.kubelet_object_id

  depends_on = [
    module.aks,
    module.acr_private_endpoint
  ]
}

module "jump_host" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.3.5"

  name                = local.jump_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  deployment_mode   = "vm"
  subnet_id         = module.vnet.subnet_ids[local.jump_subnet_name]
  admin_username    = local.jump_admin_username
  ssh_public_key    = one(local.jump_ssh_authorized_keys)
  vm_size           = local.jump_shape
  custom_data       = local.jump_custom_data
  attach_nsg_to_nic = true
  nsg_id            = module.jump_nsg.id

  tags = local.tags

  depends_on = [
    module.jump_nsg,
    module.nat_gateway,
    module.aks
  ]
}
