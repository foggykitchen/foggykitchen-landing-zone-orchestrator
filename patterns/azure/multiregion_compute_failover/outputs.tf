output "primary_site" {
  description = "Primary Azure region outputs."
  value = {
    location                = local.primary_location
    vnet_id                 = module.primary_vnet.vnet_id
    app_subnet_id           = module.primary_vnet.subnet_ids[local.primary_app_subnet_name]
    load_balancer_id        = module.primary_load_balancer.lb_id
    load_balancer_public_ip = module.primary_lb_public_ip.ip_address
    vmss_id                 = module.primary_compute.vmss_id
    nat_gateway_id          = module.primary_nat_gateway.nat_gateway_id
  }
}

output "standby_site" {
  description = "Standby Azure region outputs."
  value = {
    location                = local.standby_location
    vnet_id                 = module.standby_vnet.vnet_id
    app_subnet_id           = module.standby_vnet.subnet_ids[local.standby_app_subnet_name]
    load_balancer_id        = module.standby_load_balancer.lb_id
    load_balancer_public_ip = module.standby_lb_public_ip.ip_address
    vmss_id                 = module.standby_compute.vmss_id
    nat_gateway_id          = module.standby_nat_gateway.nat_gateway_id
  }
}

output "frontdoor_failover" {
  description = "Azure Front Door failover outputs."
  value = {
    profile_id         = module.frontdoor.profile_id
    profile_name       = module.frontdoor.profile_name
    endpoint_id        = module.frontdoor.endpoint_id
    endpoint_host_name = module.frontdoor.endpoint_host_name
    origin_group_ids   = module.frontdoor.origin_group_ids
    origin_ids         = module.frontdoor.origin_ids
    route_ids          = module.frontdoor.route_ids
  }
}
