resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.primary_location
  tags     = local.tags
}

module "primary_vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = local.primary_vnet_name
  location            = local.primary_location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.primary_vnet_cidr]

  subnets = {
    (local.primary_app_subnet_name) = {
      address_prefixes = [local.primary_app_subnet_cidr]
    }
  }

  tags = merge(local.tags, { region_role = "primary" })
}

module "standby_vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = local.standby_vnet_name
  location            = local.standby_location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.standby_vnet_cidr]

  subnets = {
    (local.standby_app_subnet_name) = {
      address_prefixes = [local.standby_app_subnet_cidr]
    }
  }

  tags = merge(local.tags, { region_role = "standby" })
}

module "primary_app_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.1"

  name                = "nsg-${local.primary_name}"
  location            = local.primary_location
  resource_group_name = azurerm_resource_group.this.name

  rules = [
    {
      name                       = "allow-http-through-public-lb"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = local.primary_app_subnet_cidr
      description                = "Allow HTTP traffic delivered through the public Standard Load Balancer."
    },
    {
      name                       = "allow-azure-lb-probe"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = local.primary_app_subnet_cidr
      description                = "Allow Azure Load Balancer health probes."
    },
    {
      name                       = "allow-internet-egress"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = local.primary_app_subnet_cidr
      destination_address_prefix = "Internet"
      description                = "Allow outbound package installation and updates through NAT Gateway."
    }
  ]

  subnet_associations = {
    app = {
      subnet_id = module.primary_vnet.subnet_ids[local.primary_app_subnet_name]
    }
  }

  tags = merge(local.tags, { region_role = "primary" })
}

module "standby_app_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.1"

  name                = "nsg-${local.standby_name}"
  location            = local.standby_location
  resource_group_name = azurerm_resource_group.this.name

  rules = [
    {
      name                       = "allow-http-through-public-lb"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = local.standby_app_subnet_cidr
      description                = "Allow HTTP traffic delivered through the public Standard Load Balancer."
    },
    {
      name                       = "allow-azure-lb-probe"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = local.standby_app_subnet_cidr
      description                = "Allow Azure Load Balancer health probes."
    },
    {
      name                       = "allow-internet-egress"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = local.standby_app_subnet_cidr
      destination_address_prefix = "Internet"
      description                = "Allow outbound package installation and updates through NAT Gateway."
    }
  ]

  subnet_associations = {
    app = {
      subnet_id = module.standby_vnet.subnet_ids[local.standby_app_subnet_name]
    }
  }

  tags = merge(local.tags, { region_role = "standby" })
}

module "primary_nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.1"

  name                = local.primary_nat_gateway_name
  location            = local.primary_location
  resource_group_name = azurerm_resource_group.this.name
  create_public_ip    = true
  public_ip_name      = local.primary_nat_gateway_public_ip_name

  subnet_associations = {
    app = {
      subnet_id = module.primary_vnet.subnet_ids[local.primary_app_subnet_name]
    }
  }

  tags = merge(local.tags, { region_role = "primary" })
}

module "standby_nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.1"

  name                = local.standby_nat_gateway_name
  location            = local.standby_location
  resource_group_name = azurerm_resource_group.this.name
  create_public_ip    = true
  public_ip_name      = local.standby_nat_gateway_public_ip_name

  subnet_associations = {
    app = {
      subnet_id = module.standby_vnet.subnet_ids[local.standby_app_subnet_name]
    }
  }

  tags = merge(local.tags, { region_role = "standby" })
}

module "primary_lb_public_ip" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-public-ip.git?ref=v1.0.0"

  name                = local.primary_pip_name
  location            = local.primary_location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(local.tags, { region_role = "primary" })
}

module "standby_lb_public_ip" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-public-ip.git?ref=v1.0.0"

  name                = local.standby_pip_name
  location            = local.standby_location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(local.tags, { region_role = "standby" })
}

module "primary_load_balancer" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-loadbalancer.git?ref=v1.2.1"

  name                = local.primary_lb_name
  location            = local.primary_location
  resource_group_name = azurerm_resource_group.this.name
  frontend_type       = "public"
  create_public_ip    = false
  public_ip_id        = module.primary_lb_public_ip.id
  sku                 = local.lb_sku
  probe               = local.lb_probe
  rule                = local.lb_rule
  tags                = merge(local.tags, { region_role = "primary" })
}

module "standby_load_balancer" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-loadbalancer.git?ref=v1.2.1"

  name                = local.standby_lb_name
  location            = local.standby_location
  resource_group_name = azurerm_resource_group.this.name
  frontend_type       = "public"
  create_public_ip    = false
  public_ip_id        = module.standby_lb_public_ip.id
  sku                 = local.lb_sku
  probe               = local.lb_probe
  rule                = local.lb_rule
  tags                = merge(local.tags, { region_role = "standby" })
}

module "primary_compute" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.4.1"

  name                = "vmss-${local.primary_name}"
  location            = local.primary_location
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode     = "vmss"
  subnet_id           = module.primary_vnet.subnet_ids[local.primary_app_subnet_name]
  admin_username      = local.admin_username
  ssh_public_key      = local.ssh_public_key
  vm_size             = local.vm_size
  image_reference     = local.image_reference
  instance_count      = local.primary_instance_count
  enable_autoscale    = local.primary_autoscale_enabled

  autoscale_min_instances           = local.primary_autoscale_min_instances
  autoscale_max_instances           = local.primary_autoscale_max_instances
  autoscale_cpu_scale_out_threshold = local.primary_scale_out_threshold
  autoscale_cpu_scale_in_threshold  = local.primary_scale_in_threshold
  custom_data                       = local.primary_custom_data
  identity_type                     = "None"
  lb_attachment                     = { backend_pool_id = module.primary_load_balancer.backend_pool_id }
  tags                              = merge(local.tags, { region_role = "primary" })

  depends_on = [
    module.primary_app_nsg,
    module.primary_nat_gateway
  ]
}

module "standby_compute" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.4.1"

  name                = "vmss-${local.standby_name}"
  location            = local.standby_location
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode     = "vmss"
  subnet_id           = module.standby_vnet.subnet_ids[local.standby_app_subnet_name]
  admin_username      = local.admin_username
  ssh_public_key      = local.ssh_public_key
  vm_size             = local.vm_size
  image_reference     = local.image_reference
  instance_count      = local.standby_instance_count
  enable_autoscale    = local.standby_autoscale_enabled

  autoscale_min_instances           = local.standby_autoscale_min_instances
  autoscale_max_instances           = local.standby_autoscale_max_instances
  autoscale_cpu_scale_out_threshold = local.standby_scale_out_threshold
  autoscale_cpu_scale_in_threshold  = local.standby_scale_in_threshold
  custom_data                       = local.standby_custom_data
  identity_type                     = "None"
  lb_attachment                     = { backend_pool_id = module.standby_load_balancer.backend_pool_id }
  tags                              = merge(local.tags, { region_role = "standby" })

  depends_on = [
    module.standby_app_nsg,
    module.standby_nat_gateway
  ]
}

module "frontdoor" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-frontdoor.git?ref=v0.1.0"

  name                = local.frontdoor_name
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = local.frontdoor_sku_name

  endpoint = {
    name    = local.frontdoor_endpoint_name
    enabled = true
  }

  origin_groups = {
    app = {
      name = local.frontdoor_origin_group
      health_probe = {
        interval_in_seconds = 30
        path                = "/"
        protocol            = "Http"
        request_type        = "GET"
      }
      load_balancing = {
        additional_latency_in_milliseconds = 50
        sample_size                        = 4
        successful_samples_required        = 3
      }
    }
  }

  origins = {
    primary = {
      name                           = "primary"
      origin_group_key               = "app"
      host_name                      = module.primary_lb_public_ip.ip_address
      origin_host_header             = module.primary_lb_public_ip.ip_address
      enabled                        = true
      certificate_name_check_enabled = false
      http_port                      = 80
      https_port                     = 443
      priority                       = 1
      weight                         = 1000
    }
    standby = {
      name                           = "standby"
      origin_group_key               = "app"
      host_name                      = module.standby_lb_public_ip.ip_address
      origin_host_header             = module.standby_lb_public_ip.ip_address
      enabled                        = true
      certificate_name_check_enabled = false
      http_port                      = 80
      https_port                     = 443
      priority                       = 2
      weight                         = 1000
    }
  }

  routes = {
    default = {
      name                   = local.frontdoor_route_name
      origin_group_key       = "app"
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      forwarding_protocol    = "HttpOnly"
      https_redirect_enabled = true
      link_to_default_domain = true
      enabled                = true
    }
  }

  tags = local.tags
}
