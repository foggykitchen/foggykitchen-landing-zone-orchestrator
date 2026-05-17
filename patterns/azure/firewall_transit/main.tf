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
    AzureFirewallSubnet = {
      address_prefixes                              = [local.hub.firewall_subnet.cidr]
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
    workload = {
      address_prefixes                              = [each.value.subnet.cidr]
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = true
      service_endpoints                             = []
      delegations                                   = []
    }
  }

  tags = merge(local.tags, { spoke = each.key })
}

module "hub_to_spokes_peering" {
  for_each = module.spoke_vnets
  source   = "git::https://github.com/mlinxfeld/terraform-az-fk-vnet-peering.git?ref=main"

  resource_group_name          = azurerm_resource_group.this.name
  vnet_1_id                    = module.hub_vnet.vnet_id
  vnet_1_name                  = module.hub_vnet.vnet_name
  vnet_2_id                    = each.value.vnet_id
  vnet_2_name                  = each.value.vnet_name
  allow_virtual_network_access = true
  allow_forwarded_traffic      = try(local.peering.allow_forwarded_traffic, true)
  allow_gateway_transit        = false
  use_remote_gateways          = false
  tags                         = merge(local.tags, { peering = each.key })
}

module "firewall_public_ip" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-public-ip.git?ref=main"

  name                = local.firewall.public_ip_name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

module "firewall" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-firewall.git?ref=v0.2.0"

  name                = local.firewall.name
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  sku_tier            = local.firewall.sku_tier
  threat_intel_mode   = try(local.firewall.threat_intel_mode, "Alert")

  ip_configurations = {
    primary = {
      subnet_id            = module.hub_vnet.subnet_ids["AzureFirewallSubnet"]
      public_ip_address_id = module.firewall_public_ip.id
    }
  }

  network_rule_collections     = local.firewall_network_rule_collections
  application_rule_collections = local.firewall_application_rule_collections
  tags                         = local.tags
}

module "routing" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-routing.git?ref=main"

  resource_group_name = azurerm_resource_group.this.name
  route_tables = {
    for spoke_key, spoke in local.spokes : "rt-${spoke_key}" => {
      location = local.location
      routes = [
        {
          name           = "to-peer-spoke-via-firewall"
          address_prefix = local.spokes[spoke_key == "spoke1" ? "spoke2" : "spoke1"].address_space[0]
          next_hop_type  = "VirtualAppliance"
          next_hop_ip    = module.firewall.firewall_private_ip
        },
        {
          name           = "default-to-internet-via-firewall"
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "VirtualAppliance"
          next_hop_ip    = module.firewall.firewall_private_ip
        }
      ]
      subnet_ids = [
        module.spoke_vnets[spoke_key].subnet_ids["workload"]
      ]
    }
  }
  tags = local.tags
}

module "compute" {
  for_each = local.compute_instances
  source   = "git::https://github.com/mlinxfeld/terraform-az-fk-compute.git?ref=v0.3.5"

  name                          = each.value.name
  location                      = local.location
  resource_group_name           = azurerm_resource_group.this.name
  subnet_id                     = module.spoke_vnets[split(".", each.value.subnet_ref)[0]].subnet_ids["workload"]
  vm_size                       = each.value.size
  admin_username                = each.value.admin_username
  ssh_public_key                = var.admin_ssh_public_key
  private_ip_address_allocation = "Static"
  private_ip_address            = each.value.private_ip_address
  image_reference               = each.value.image
  tags                          = merge(local.tags, { workload = each.key })
}
