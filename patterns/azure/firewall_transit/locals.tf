locals {
  config       = yamldecode(file(var.payload_file))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  networking   = local.config.networking
  peering      = local.config.peering
  firewall     = local.config.firewall
  routing      = local.config.routing
  compute      = local.config.compute

  location            = local.cloud.location
  resource_group_name = local.cloud.resource_group.name
  tags = merge(
    local.landing_zone.default_tags,
    {
      owner = local.landing_zone.owner
    }
  )

  hub = local.networking.hub

  spokes = {
    for spoke_key, spoke in local.networking.spokes : spoke_key => {
      name          = spoke.name
      address_space = spoke.address_space
      subnet = {
        name = spoke.subnet.name
        cidr = spoke.subnet.cidr
      }
    }
  }

  compute_instances = {
    for instance_key, instance in local.compute.instances : instance_key => {
      name               = instance.name
      subnet_ref         = instance.subnet_ref
      size               = instance.size
      private_ip_address = instance.private_ip_address
      image              = instance.image
      admin_username     = try(instance.admin_username, "azureuser")
    }
  }

  firewall_network_rule_collections = [
    {
      name     = "allow-east-west"
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                  = "spoke1-to-spoke2"
          protocols             = ["Any"]
          source_addresses      = [local.spokes.spoke1.address_space[0]]
          destination_addresses = [local.spokes.spoke2.address_space[0]]
          destination_ports     = ["*"]
        },
        {
          name                  = "spoke2-to-spoke1"
          protocols             = ["Any"]
          source_addresses      = [local.spokes.spoke2.address_space[0]]
          destination_addresses = [local.spokes.spoke1.address_space[0]]
          destination_ports     = ["*"]
        }
      ]
    }
  ]

  firewall_application_rule_collections = [
    {
      name     = "allow-web-egress"
      priority = 200
      action   = "Allow"
      rules = [
        {
          name             = "spokes-web"
          source_addresses = [for _, spoke in local.spokes : spoke.address_space[0]]
          target_fqdns     = ["*"]
          protocols = [
            {
              type = "Http"
              port = 80
            },
            {
              type = "Https"
              port = 443
            }
          ]
        }
      ]
    }
  ]
}
