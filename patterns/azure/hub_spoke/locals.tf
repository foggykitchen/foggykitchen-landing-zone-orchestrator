locals {
  config        = yamldecode(file(var.payload_file))
  landing_zone  = local.config.landing_zone
  cloud         = local.config.cloud
  architecture  = local.config.architecture
  features      = local.config.features
  networking    = local.config.networking
  peering       = local.config.peering
  routing       = try(local.config.routing, { enabled = false })
  security      = local.config.security
  nat_gateway   = local.config.nat_gateway
  bastion       = local.config.bastion
  private_dns   = try(local.config.private_dns, { enabled = false })
  compute       = try(local.config.compute, { enabled = false })
  load_balancer = try(local.config.load_balancer, { enabled = false })

  payload_dir = dirname(var.payload_file)

  tags = merge(
    local.landing_zone.default_tags,
    {
      owner = local.landing_zone.owner
    }
  )

  resource_group_name = local.cloud.resource_group.name
  location            = local.cloud.location

  hub = local.networking.hub

  spokes = {
    for spoke_key, spoke in local.networking.spokes : spoke_key => {
      name          = spoke.name
      address_space = spoke.address_space
      subnets = {
        for subnet_key, subnet in spoke.subnets : subnet_key => {
          name  = subnet.name
          cidr  = subnet.cidr
          key   = "${spoke_key}.${subnet_key}"
          is_pe = subnet_key == "private_endpoints"
        }
      }
    }
  }

  hub_subnets = {
    for subnet_key, subnet in local.hub.subnets : subnet_key => {
      name = subnet.name
      cidr = subnet.cidr
      key  = "hub.${subnet_key}"
    }
  }

  subnet_cidrs_by_ref = merge(
    { for subnet_key, subnet in local.hub_subnets : "hub.${subnet_key}" => subnet.cidr },
    merge([
      for spoke_key, spoke in local.spokes : {
        for subnet_key, subnet in spoke.subnets : "${spoke_key}.${subnet_key}" => subnet.cidr
      }
    ]...)
  )

  subnet_names_by_ref = merge(
    { for subnet_key, subnet in local.hub_subnets : "hub.${subnet_key}" => subnet.name },
    merge([
      for spoke_key, spoke in local.spokes : {
        for subnet_key, subnet in spoke.subnets : "${spoke_key}.${subnet_key}" => subnet.name
      }
    ]...)
  )

  subnet_ids_by_ref = merge(
    { for subnet_key, subnet in local.hub_subnets : "hub.${subnet_key}" => module.hub_vnet.subnet_ids[subnet.name] },
    merge([
      for spoke_key, spoke in local.spokes : {
        for subnet_key, subnet in spoke.subnets : "${spoke_key}.${subnet_key}" => module.spoke_vnets[spoke_key].subnet_ids[subnet.name]
      }
    ]...)
  )

  vnet_ids_by_ref = merge(
    {
      hub = module.hub_vnet.vnet_id
    },
    {
      for spoke_key, mod in module.spoke_vnets : spoke_key => mod.vnet_id
    }
  )

  nat_subnet_refs = toset(try(local.nat_gateway.attach_to_subnets, []))

  nat_subnet_refs_by_vnet = {
    for vnet_key in distinct([for subnet_ref in local.nat_subnet_refs : split(".", subnet_ref)[0]]) :
    vnet_key => [for subnet_ref in local.nat_subnet_refs : subnet_ref if split(".", subnet_ref)[0] == vnet_key]
  }

  route_next_hop_vm_refs = toset(flatten([
    for _, route_table in try(local.routing.route_tables, {}) : [
      for route in try(route_table.routes, []) : try(route.next_hop_vm_ref, null)
    ]
  ]))

  compute_instances = {
    for instance_key, instance in try(local.compute.instances, {}) : instance_key => {
      name                          = instance.name
      subnet_ref                    = instance.subnet_ref
      size                          = instance.size
      admin_username                = try(instance.admin_username, "azureuser")
      deployment_mode               = try(instance.deployment_mode, "vm")
      enable_ip_forwarding          = try(instance.enable_ip_forwarding, false)
      private_ip_address_allocation = try(instance.private_ip_address_allocation, "Dynamic")
      private_ip_address            = try(instance.private_ip_address, null)
      attach_nsg_to_nic             = try(instance.attach_nsg_to_nic, false)
      nsg_id                        = try(instance.nsg_id, null) != null ? instance.nsg_id : (contains(local.route_next_hop_vm_refs, instance_key) && try(instance.attach_nsg_to_nic, false) ? module.router_vm_nsg[0].id : null)
      identity_type                 = try(instance.identity_type, "SystemAssigned")
      image = {
        publisher = try(instance.image.publisher, "Canonical")
        offer     = try(instance.image.offer, "ubuntu-24_04-lts")
        sku       = try(instance.image.sku, "server")
        version   = try(instance.image.version, "latest")
      }
      custom_data = try(instance.cloud_init, null) != null ? filebase64("${local.payload_dir}/${instance.cloud_init}") : null
    }
  }

  load_balancer_backend_refs = toset(try(local.load_balancer.backend_vm_refs, []))

  load_balancer_frontend_subnet_id = try(local.load_balancer.frontend_subnet_ref, null) != null ? local.subnet_ids_by_ref[local.load_balancer.frontend_subnet_ref] : null

  route_tables = !local.features.routing || !try(local.routing.enabled, false) ? {} : (
    try(local.routing.route_tables, null) != null ? {
      for route_table_name, route_table in local.routing.route_tables : route_table_name => {
        location = local.location
        routes = [
          for route in try(route_table.routes, []) : {
            name           = route.name
            address_prefix = route.address_prefix
            next_hop_type  = route.next_hop_type
            next_hop_ip    = route.next_hop_type == "VirtualAppliance" ? (try(route.next_hop_ip, null) != null ? route.next_hop_ip : try(module.compute[route.next_hop_vm_ref].vm_private_ip, null)) : null
          }
        ]
        subnet_ids = [for subnet_ref in try(route_table.subnet_refs, []) : local.subnet_ids_by_ref[subnet_ref]]
      }
      } : {
      app_frontend = {
        location = local.location
        routes = try(local.routing.firewall_next_hop.enabled, false) ? [
          {
            name           = "default-via-firewall"
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "VirtualAppliance"
            next_hop_ip    = local.routing.firewall_next_hop.ip_address
          }
        ] : []
        subnet_ids = [local.subnet_ids_by_ref["app.frontend"]]
      }
      app_backend = {
        location = local.location
        routes = try(local.routing.firewall_next_hop.enabled, false) ? [
          {
            name           = "default-via-firewall"
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "VirtualAppliance"
            next_hop_ip    = local.routing.firewall_next_hop.ip_address
          }
        ] : []
        subnet_ids = [local.subnet_ids_by_ref["app.backend"]]
      }
      data_database = {
        location = local.location
        routes = try(local.routing.firewall_next_hop.enabled, false) ? [
          {
            name           = "default-via-firewall"
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "VirtualAppliance"
            next_hop_ip    = local.routing.firewall_next_hop.ip_address
          }
        ] : []
        subnet_ids = [local.subnet_ids_by_ref["data.database"]]
      }
      data_private_endpoints = {
        location   = local.location
        routes     = []
        subnet_ids = [local.subnet_ids_by_ref["data.private_endpoints"]]
      }
    }
  )

  private_dns_zone_definitions = local.features.private_dns && try(local.private_dns.enabled, false) ? (
    try(length(local.private_dns.zones), 0) > 0 && can(local.private_dns.zones[0].name) ? {
      for zone in local.private_dns.zones : zone.name => {
        link_to_vnets = toset(try(zone.link_to_vnets, try(local.private_dns.link_to_vnets, concat(["hub"], keys(local.spokes)))))
      }
      } : {
      for zone_name in try(local.private_dns.zones, []) : zone_name => {
        link_to_vnets = toset(try(local.private_dns.link_to_vnets, concat(["hub"], keys(local.spokes))))
      }
    }
  ) : {}

  private_dns_vnet_links_by_zone = {
    for zone_name, zone in local.private_dns_zone_definitions : zone_name => {
      for vnet_ref in zone.link_to_vnets : vnet_ref => {
        vnet_id              = local.vnet_ids_by_ref[vnet_ref]
        registration_enabled = false
      }
    }
  }
}
