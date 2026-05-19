resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

module "hub_vnet" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-vnet.git?ref=main"

  name                = local.hub.name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = local.hub.address_space

  subnets = {
    for subnet_key, subnet in local.hub_subnets : subnet.name => {
      address_prefixes                              = [subnet.cidr]
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = true
      service_endpoints                             = []
      delegations                                   = []
    }
  }

  tags = local.tags
}

module "spoke_vnets" {
  for_each = local.spokes
  source   = "git::https://github.com/mlinxfeld/terraform-az-fk-vnet.git?ref=main"

  name                = each.value.name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = each.value.address_space

  subnets = {
    for subnet_key, subnet in each.value.subnets : subnet.name => {
      address_prefixes                              = [subnet.cidr]
      private_endpoint_network_policies             = subnet.is_pe ? "Disabled" : "Enabled"
      private_link_service_network_policies_enabled = true
      service_endpoints                             = []
      delegations                                   = []
    }
  }

  tags = merge(local.tags, { spoke = each.key })
}

module "hub_to_spoke_peering" {
  for_each = local.features.vnet_peering && local.peering.hub_to_spokes ? module.spoke_vnets : {}
  source   = "git::https://github.com/mlinxfeld/terraform-az-fk-vnet-peering.git?ref=main"

  resource_group_name          = azurerm_resource_group.this.name
  vnet_1_id                    = module.hub_vnet.vnet_id
  vnet_1_name                  = module.hub_vnet.vnet_name
  vnet_2_id                    = each.value.vnet_id
  vnet_2_name                  = each.value.vnet_name
  allow_virtual_network_access = true
  allow_forwarded_traffic      = local.peering.allow_forwarded_traffic
  allow_gateway_transit        = local.peering.allow_gateway_transit
  use_remote_gateways          = local.peering.use_remote_gateways
  tags                         = merge(local.tags, { peering = each.key })
}

module "routing" {
  count  = local.features.routing && try(local.routing.enabled, false) ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-routing.git?ref=main"

  resource_group_name = azurerm_resource_group.this.name
  route_tables        = local.route_tables
  tags                = local.tags
}

module "hub_shared_nsg" {
  count  = local.features.nsg && local.security.nsg.enabled ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-nsg.git?ref=main"

  name                = "nsg-fk-hub-shared"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  rules = [
    {
      name                       = "deny-internet-inbound"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Deny direct inbound traffic from the Internet."
    }
  ]
  subnet_associations = {
    shared = {
      subnet_id = local.subnet_ids_by_ref["hub.shared"]
    }
  }
  tags = local.tags
}

module "app_frontend_nsg" {
  count  = local.features.nsg && local.security.nsg.enabled ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-nsg.git?ref=main"

  name                = "nsg-fk-app-frontend"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  rules = [
    {
      name                       = "deny-internet-inbound"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Deny direct inbound traffic from the Internet."
    }
  ]
  subnet_associations = {
    frontend = {
      subnet_id = local.subnet_ids_by_ref["app.frontend"]
    }
  }
  tags = local.tags
}

module "app_backend_nsg" {
  count  = local.features.nsg && local.security.nsg.enabled ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-nsg.git?ref=main"

  name                = "nsg-fk-app-backend"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  rules = concat(
    local.features.internal_load_balancer && try(local.load_balancer.enabled, false) ? [
      {
        name                       = "allow-http-from-azure-lb"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = tostring(local.load_balancer.listener.port)
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
        description                = "Allow application traffic from the internal load balancer."
      }
    ] : [],
    [
      {
        name                       = "allow-ssh-from-bastion"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = local.subnet_cidrs_by_ref["hub.bastion"]
        destination_address_prefix = "*"
        description                = "Allow operator SSH only from Azure Bastion subnet."
      },
      {
        name                       = "deny-internet-inbound"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Deny direct inbound traffic from the Internet."
      }
    ]
  )
  subnet_associations = {
    backend = {
      subnet_id = local.subnet_ids_by_ref["app.backend"]
    }
  }
  tags = local.tags
}

module "data_database_nsg" {
  count  = local.features.nsg && local.security.nsg.enabled ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-nsg.git?ref=main"

  name                = "nsg-fk-data-database"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  rules = [
    {
      name                       = "allow-ssh-from-bastion"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = local.subnet_cidrs_by_ref["hub.bastion"]
      destination_address_prefix = "*"
      description                = "Allow operator SSH only from Azure Bastion subnet."
    },
    {
      name                       = "deny-internet-inbound"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Deny direct inbound traffic from the Internet."
    }
  ]
  subnet_associations = {
    database = {
      subnet_id = local.subnet_ids_by_ref["data.database"]
    }
  }
  tags = local.tags
}

module "data_private_endpoints_nsg" {
  count  = local.features.nsg && local.security.nsg.enabled ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-nsg.git?ref=main"

  name                = "nsg-fk-data-private-endpoints"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  rules = [
    {
      name                       = "deny-internet-inbound"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Deny direct inbound traffic from the Internet."
    }
  ]
  subnet_associations = {
    private_endpoints = {
      subnet_id = local.subnet_ids_by_ref["data.private_endpoints"]
    }
  }
  tags = local.tags
}

module "router_vm_nsg" {
  count  = local.features.nsg && local.security.nsg.enabled && length(local.route_next_hop_vm_refs) > 0 ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-nsg.git?ref=main"

  name                = "nsg-fk-router-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  rules = [
    {
      name                       = "allow-spokes-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefixes    = [for _, spoke in local.spokes : spoke.address_space[0]]
      destination_address_prefix = "*"
      description                = "Allow forwarded traffic from all spoke VNets to the router VM."
    },
    {
      name                         = "allow-spokes-outbound"
      priority                     = 110
      direction                    = "Outbound"
      access                       = "Allow"
      protocol                     = "*"
      source_port_range            = "*"
      destination_port_range       = "*"
      source_address_prefix        = "*"
      destination_address_prefixes = [for _, spoke in local.spokes : spoke.address_space[0]]
      description                  = "Allow forwarded traffic from the router VM back to all spoke VNets."
    }
  ]
  tags = local.tags
}

module "nat_public_ip" {
  for_each = local.features.nat_gateway && local.nat_gateway.enabled ? local.nat_subnet_refs_by_vnet : {}
  source   = "git::https://github.com/mlinxfeld/terraform-az-fk-public-ip.git?ref=main"

  name                = "natgw-fk-${each.key}-${local.landing_zone.environment}-pip"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

module "nat_gateway" {
  for_each = local.features.nat_gateway && local.nat_gateway.enabled ? local.nat_subnet_refs_by_vnet : {}
  source   = "git::https://github.com/mlinxfeld/terraform-az-fk-natgw.git?ref=main"

  name                = "natgw-fk-${each.key}-${local.landing_zone.environment}"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  create_public_ip    = false
  public_ip_id        = module.nat_public_ip[each.key].id
  subnet_associations = {
    for subnet_ref in each.value : replace(subnet_ref, ".", "-") => {
      subnet_id = local.subnet_ids_by_ref[subnet_ref]
    }
  }
  tags = local.tags
}

module "bastion" {
  count  = local.features.bastion && local.bastion.enabled ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-bastion.git?ref=main"

  name                = local.bastion.name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  bastion_subnet_id   = local.subnet_ids_by_ref["hub.bastion"]
  sku                 = local.bastion.sku
  tunneling_enabled   = true
  ip_connect_enabled  = true
  tags                = local.tags
}

module "private_dns" {
  for_each = local.private_dns_zone_definitions
  source   = "git::https://github.com/mlinxfeld/terraform-az-fk-private-dns.git?ref=main"

  resource_group_name    = azurerm_resource_group.this.name
  private_dns_zone_names = toset([each.key])
  vnet_links             = local.private_dns_vnet_links_by_zone[each.key]
  tags                   = local.tags
}

module "internal_load_balancer" {
  count  = local.features.internal_load_balancer && try(local.load_balancer.enabled, false) ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-loadbalancer.git?ref=v1.2.0"

  name                = local.load_balancer.name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name

  frontend_type                 = "private"
  frontend_name                 = "internal-frontend"
  private_frontend_subnet_id    = local.load_balancer_frontend_subnet_id
  private_ip_address_allocation = try(local.load_balancer.private_ip_address, null) != null ? "Static" : "Dynamic"
  private_ip_address            = try(local.load_balancer.private_ip_address, null)

  backend_pool_name = "app-backend-pool"

  probe = {
    name                = "app-health-probe"
    protocol            = local.load_balancer.health_probe.protocol
    port                = local.load_balancer.health_probe.port
    interval_in_seconds = try(local.load_balancer.health_probe.interval_in_seconds, 5)
    number_of_probes    = try(local.load_balancer.health_probe.number_of_probes, 2)
    request_path        = try(local.load_balancer.health_probe.request_path, null)
  }

  rule = {
    name                    = "app-listener"
    protocol                = local.load_balancer.listener.protocol
    frontend_port           = local.load_balancer.listener.port
    backend_port            = try(local.load_balancer.listener.backend_port, local.load_balancer.listener.port)
    idle_timeout_in_minutes = try(local.load_balancer.listener.idle_timeout_in_minutes, null)
    enable_floating_ip      = try(local.load_balancer.listener.enable_floating_ip, null)
    disable_outbound_snat   = try(local.load_balancer.listener.disable_outbound_snat, null)
  }

  tags = local.tags
}

module "compute" {
  for_each = local.features.compute && try(local.compute.enabled, false) ? local.compute_instances : {}
  source   = "git::https://github.com/mlinxfeld/terraform-az-fk-compute.git?ref=v0.3.5"

  name                          = each.value.name
  location                      = local.location
  resource_group_name           = azurerm_resource_group.this.name
  subnet_id                     = local.subnet_ids_by_ref[each.value.subnet_ref]
  deployment_mode               = each.value.deployment_mode
  vm_size                       = each.value.size
  admin_username                = each.value.admin_username
  ssh_public_key                = var.admin_ssh_public_key
  identity_type                 = each.value.identity_type
  image_reference               = each.value.image
  custom_data                   = each.value.custom_data
  enable_ip_forwarding          = each.value.enable_ip_forwarding
  private_ip_address_allocation = each.value.private_ip_address_allocation
  private_ip_address            = each.value.private_ip_address
  attach_nsg_to_nic             = each.value.attach_nsg_to_nic
  nsg_id                        = each.value.nsg_id
  lb_attachment = contains(local.load_balancer_backend_refs, each.key) && local.features.internal_load_balancer && try(local.load_balancer.enabled, false) ? {
    backend_pool_id = module.internal_load_balancer[0].backend_pool_id
  } : null
  tags = merge(local.tags, { workload = each.key })
}
