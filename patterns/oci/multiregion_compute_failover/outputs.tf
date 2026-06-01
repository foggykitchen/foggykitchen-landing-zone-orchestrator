output "primary_site" {
  description = "Primary region outputs."
  value = {
    region            = local.primary_region
    vcn_id            = module.vcn_primary.vcn_id
    load_balancer_id  = module.lb_primary.load_balancer_id
    load_balancer_ips = module.lb_primary.load_balancer_public_ips
    drg_id            = module.drg_primary.drg_id
  }
}

output "standby_site" {
  description = "Standby region outputs."
  value = {
    region            = local.standby_region
    vcn_id            = module.vcn_standby.vcn_id
    load_balancer_id  = module.lb_standby.load_balancer_id
    load_balancer_ips = module.lb_standby.load_balancer_public_ips
    drg_id            = module.drg_standby.drg_id
  }
}

output "dns_failover" {
  description = "DNS steering outputs."
  value = {
    zone                          = module.dns_steering.zone
    steering_policy               = module.dns_steering.steering_policy
    steering_policy_attachment_id = module.dns_steering.steering_policy_attachment_id
    health_check_monitor_id       = module.dns_steering.health_check_monitor_id
  }
}
