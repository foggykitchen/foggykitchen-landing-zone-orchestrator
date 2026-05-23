module "vcns" {
  for_each = local.vcn_module_inputs
  source   = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=main"

  compartment_ocid = local.compartment_ocid
  name             = each.value.name
  dns_label        = each.value.dns_label
  vcn_cidr_blocks  = each.value.vcn_cidr_blocks
  security_lists   = each.value.security_lists
  subnets          = each.value.subnets
  defined_tags     = local.defined_tags
  freeform_tags    = merge(local.freeform_tags, { vcn = each.key })
}

module "lpg" {
  source = "git::https://github.com/mlinxfeld/terraform-oci-fk-lpg.git?ref=main"

  compartment_ocid_1 = local.compartment_ocid
  compartment_ocid_2 = local.compartment_ocid
  vcn_1_id           = module.vcns[local.left_vcn_key].vcn_id
  vcn_1_name         = module.vcns[local.left_vcn_key].vcn_name
  vcn_2_id           = module.vcns[local.right_vcn_key].vcn_id
  vcn_2_name         = module.vcns[local.right_vcn_key].vcn_name
  lpg_1_display_name = "${module.vcns[local.left_vcn_key].vcn_name}-lpg"
  lpg_2_display_name = "${module.vcns[local.right_vcn_key].vcn_name}-lpg"
  peer_gateways      = local.connectivity.lpg.enabled
  defined_tags       = local.defined_tags
  freeform_tags      = local.freeform_tags
}

resource "oci_core_default_route_table" "vcn_defaults" {
  for_each = local.vcns

  manage_default_resource_id = module.vcns[each.key].default_route_table_id
  compartment_id             = local.compartment_ocid
  display_name               = "default-rt-${each.value.name}"

  dynamic "route_rules" {
    for_each = local.route_targets_by_vcn[each.key]
    content {
      description       = "Route ${route_rules.value} via LPG."
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = each.key == local.left_vcn_key ? module.lpg.lpg_1_id : module.lpg.lpg_2_id
    }
  }
}

module "load_balancer" {
  count  = local.load_balancer.enabled ? 1 : 0
  source = "git::https://github.com/mlinxfeld/terraform-oci-fk-loadbalancer.git?ref=main"

  name             = local.load_balancer.name
  compartment_ocid = local.compartment_ocid
  display_name     = local.load_balancer.name
  subnet_ids = [
    module.vcns[local.app_vcn_key].subnet_ids[local.app_subnet_key]
  ]
  is_private = local.load_balancer.type == "private"
  shape      = "flexible"
  shape_details = {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }
  backend_set_name = "app-backend-set"
  health_checker = {
    protocol = local.load_balancer.health_checker.protocol
    port     = local.load_balancer.health_checker.port
    url_path = try(local.load_balancer.health_checker.url_path, null)
  }
  listener = {
    name     = "app-listener"
    port     = local.load_balancer.listener.port
    protocol = local.load_balancer.listener.protocol
  }
  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}

module "compute" {
  for_each = local.compute.enabled ? local.compute_instances : {}
  source   = "git::https://github.com/foggykitchen/terraform-oci-fk-compute.git?ref=main"

  name             = each.value.name
  compartment_ocid = local.compartment_ocid
  tenancy_ocid     = local.tenancy_ocid
  deployment_mode  = "instance"
  shape            = each.value.shape
  shape_config = each.value.ocpus != null && each.value.memory_in_gbs != null ? {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory_in_gbs
  } : null
  subnet_id                = module.vcns[each.value.vcn_ref].subnet_ids[each.value.subnet_ref]
  assign_public_ip         = each.value.assign_public_ip
  ssh_authorized_keys      = [var.admin_ssh_public_key]
  user_data                = each.value.user_data
  operating_system         = each.value.operating_system
  operating_system_version = each.value.operating_system_version
  lb_attachment            = contains(local.load_balancer_backend_refs, each.key) && local.load_balancer.enabled ? module.load_balancer[0].lb_attachment : null
  defined_tags             = local.defined_tags
  freeform_tags            = merge(local.freeform_tags, { workload = each.key })
}
