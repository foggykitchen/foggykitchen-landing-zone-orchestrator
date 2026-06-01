module "vcn_primary" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=main"

  compartment_ocid = local.compartment_ocid
  name             = "${local.primary_name}-vcn"
  dns_label        = "fkpri"
  vcn_cidr_blocks  = [local.primary_vcn_cidr]

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true

  extra_network_entity_ids = {
    drg = module.drg_primary.drg_id
  }

  route_tables = {
    public = {
      route_rules = [
        {
          destination        = "0.0.0.0/0"
          destination_type   = "CIDR_BLOCK"
          network_entity_key = "internet_gateway"
        }
      ]
    }
    private = {
      route_rules = [
        {
          destination        = "0.0.0.0/0"
          destination_type   = "CIDR_BLOCK"
          network_entity_key = "nat_gateway"
        },
        {
          destination        = local.standby_vcn_cidr
          destination_type   = "CIDR_BLOCK"
          network_entity_key = "drg"
        }
      ]
    }
  }

  security_lists = {
    lb_public = {
      ingress_rules = [
        for port in [80, 443] : {
          protocol = "6"
          source   = "0.0.0.0/0"
          tcp_options = {
            min = port
            max = port
          }
        }
      ]
      egress_rules = [
        {
          protocol    = "6"
          destination = "0.0.0.0/0"
        }
      ]
    }
    app_private = {
      ingress_rules = [
        {
          protocol = "6"
          source   = local.primary_vcn_cidr
        }
      ]
      egress_rules = [
        {
          protocol    = "6"
          destination = "0.0.0.0/0"
        }
      ]
    }
  }

  subnets = {
    lb_public = {
      cidr_block                 = local.primary_lb_subnet
      display_name               = "${local.primary_name}-lb-public"
      dns_label                  = "lbpub"
      route_table_key            = "public"
      security_list_keys         = ["lb_public"]
      prohibit_public_ip_on_vnic = false
    }
    app_private = {
      cidr_block                 = local.primary_app_subnet
      display_name               = "${local.primary_name}-app-private"
      dns_label                  = "apppriv"
      route_table_key            = "private"
      security_list_keys         = ["app_private"]
      prohibit_internet_ingress  = true
      prohibit_public_ip_on_vnic = true
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = merge(local.freeform_tags, { region_role = "primary" })
}

module "drg_primary" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-drg.git?ref=main"

  compartment_ocid = local.compartment_ocid
  name             = "${local.primary_name}-drg"
  display_name     = "${local.primary_name}-drg"

  vcn_attachments = {
    app = {
      vcn_id              = module.vcn_primary.vcn_id
      drg_route_table_key = "from-vcn"
    }
  }

  remote_peering_connections = {
    peer = {
      display_name = "${local.primary_name}-to-${local.standby_name}"
    }
  }

  drg_route_tables = {
    from-vcn = {
      route_rules = [
        {
          destination                            = local.standby_vcn_cidr
          destination_type                       = "CIDR_BLOCK"
          next_hop_rpc_attachment_management_key = "peer"
        }
      ]
    }
    from-rpc = {
      route_rules = [
        {
          destination             = local.primary_vcn_cidr
          destination_type        = "CIDR_BLOCK"
          next_hop_attachment_key = "app"
        }
      ]
    }
  }

  rpc_attachment_managements = {
    peer = {
      rpc_key             = "peer"
      drg_route_table_key = "from-rpc"
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = merge(local.freeform_tags, { region_role = "primary" })
}

module "vcn_standby" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=main"

  providers = {
    oci = oci.standby
  }

  compartment_ocid = local.compartment_ocid
  name             = "${local.standby_name}-vcn"
  dns_label        = "fkstd"
  vcn_cidr_blocks  = [local.standby_vcn_cidr]

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true

  extra_network_entity_ids = {
    drg = module.drg_standby.drg_id
  }

  route_tables = {
    public = {
      route_rules = [
        {
          destination        = "0.0.0.0/0"
          destination_type   = "CIDR_BLOCK"
          network_entity_key = "internet_gateway"
        }
      ]
    }
    private = {
      route_rules = [
        {
          destination        = "0.0.0.0/0"
          destination_type   = "CIDR_BLOCK"
          network_entity_key = "nat_gateway"
        },
        {
          destination        = local.primary_vcn_cidr
          destination_type   = "CIDR_BLOCK"
          network_entity_key = "drg"
        }
      ]
    }
  }

  security_lists = {
    lb_public = {
      ingress_rules = [
        for port in [80, 443] : {
          protocol = "6"
          source   = "0.0.0.0/0"
          tcp_options = {
            min = port
            max = port
          }
        }
      ]
      egress_rules = [
        {
          protocol    = "6"
          destination = "0.0.0.0/0"
        }
      ]
    }
    app_private = {
      ingress_rules = [
        {
          protocol = "6"
          source   = local.standby_vcn_cidr
        }
      ]
      egress_rules = [
        {
          protocol    = "6"
          destination = "0.0.0.0/0"
        }
      ]
    }
  }

  subnets = {
    lb_public = {
      cidr_block                 = local.standby_lb_subnet
      display_name               = "${local.standby_name}-lb-public"
      dns_label                  = "lbpub"
      route_table_key            = "public"
      security_list_keys         = ["lb_public"]
      prohibit_public_ip_on_vnic = false
    }
    app_private = {
      cidr_block                 = local.standby_app_subnet
      display_name               = "${local.standby_name}-app-private"
      dns_label                  = "apppriv"
      route_table_key            = "private"
      security_list_keys         = ["app_private"]
      prohibit_internet_ingress  = true
      prohibit_public_ip_on_vnic = true
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = merge(local.freeform_tags, { region_role = "standby" })
}

module "drg_standby" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-drg.git?ref=main"

  providers = {
    oci = oci.standby
  }

  compartment_ocid = local.compartment_ocid
  name             = "${local.standby_name}-drg"
  display_name     = "${local.standby_name}-drg"

  vcn_attachments = {
    app = {
      vcn_id              = module.vcn_standby.vcn_id
      drg_route_table_key = "from-vcn"
    }
  }

  remote_peering_connections = {
    peer = {
      display_name     = "${local.standby_name}-to-${local.primary_name}"
      peer_id          = module.drg_primary.remote_peering_connection_ids["peer"]
      peer_region_name = local.primary_region
    }
  }

  drg_route_tables = {
    from-vcn = {
      route_rules = [
        {
          destination                            = local.primary_vcn_cidr
          destination_type                       = "CIDR_BLOCK"
          next_hop_rpc_attachment_management_key = "peer"
        }
      ]
    }
    from-rpc = {
      route_rules = [
        {
          destination             = local.standby_vcn_cidr
          destination_type        = "CIDR_BLOCK"
          next_hop_attachment_key = "app"
        }
      ]
    }
  }

  rpc_attachment_managements = {
    peer = {
      rpc_key             = "peer"
      drg_route_table_key = "from-rpc"
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = merge(local.freeform_tags, { region_role = "standby" })
}

module "lb_primary" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-loadbalancer.git?ref=main"

  name             = "${local.primary_name}-lb"
  compartment_ocid = local.compartment_ocid
  subnet_ids       = [module.vcn_primary.subnet_ids["lb_public"]]
  is_private       = false
  shape            = local.lb_shape
  shape_details    = local.lb_shape_details
  health_checker   = local.lb_health_checker
  listener         = local.lb_listener
  defined_tags     = local.defined_tags
  freeform_tags    = merge(local.freeform_tags, { region_role = "primary" })
}

module "lb_standby" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-loadbalancer.git?ref=main"

  providers = {
    oci = oci.standby
  }

  name             = "${local.standby_name}-lb"
  compartment_ocid = local.compartment_ocid
  subnet_ids       = [module.vcn_standby.subnet_ids["lb_public"]]
  is_private       = false
  shape            = local.lb_shape
  shape_details    = local.lb_shape_details
  health_checker   = local.lb_health_checker
  listener         = local.lb_listener
  defined_tags     = local.defined_tags
  freeform_tags    = merge(local.freeform_tags, { region_role = "standby" })
}

module "compute_primary" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-compute.git?ref=main"

  name                          = "${local.primary_name}-pool"
  tenancy_ocid                  = local.tenancy_ocid
  compartment_ocid              = local.compartment_ocid
  deployment_mode               = "instance_pool"
  subnet_id                     = module.vcn_primary.subnet_ids["app_private"]
  shape                         = local.compute_shape
  shape_config                  = local.compute_shape_config
  operating_system              = local.compute_operating_system
  operating_system_version      = local.compute_operating_system_version
  ssh_authorized_keys           = local.ssh_authorized_keys
  assign_public_ip              = false
  instance_pool_size            = local.primary_pool_size
  enable_autoscale              = local.primary_autoscale_enabled
  autoscaling_policy_type       = "threshold"
  autoscaling_min_instances     = local.primary_autoscaling_min_instances
  autoscaling_initial_instances = local.primary_autoscaling_initial_instances
  autoscaling_max_instances     = local.primary_autoscaling_max_instances
  scale_out_cpu_threshold       = local.primary_scale_out_cpu_threshold
  scale_in_cpu_threshold        = local.primary_scale_in_cpu_threshold
  lb_attachment                 = module.lb_primary.lb_attachment
  user_data                     = local.primary_user_data
  defined_tags                  = local.defined_tags
  freeform_tags                 = merge(local.freeform_tags, { region_role = "primary" })
}

module "compute_standby" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-compute.git?ref=main"

  providers = {
    oci = oci.standby
  }

  name                          = "${local.standby_name}-pool"
  tenancy_ocid                  = local.tenancy_ocid
  compartment_ocid              = local.compartment_ocid
  deployment_mode               = "instance_pool"
  subnet_id                     = module.vcn_standby.subnet_ids["app_private"]
  shape                         = local.compute_shape
  shape_config                  = local.compute_shape_config
  operating_system              = local.compute_operating_system
  operating_system_version      = local.compute_operating_system_version
  ssh_authorized_keys           = local.ssh_authorized_keys
  assign_public_ip              = false
  instance_pool_size            = local.standby_pool_size
  enable_autoscale              = local.standby_autoscale_enabled
  autoscaling_policy_type       = "threshold"
  autoscaling_min_instances     = local.standby_autoscaling_min_instances
  autoscaling_initial_instances = local.standby_autoscaling_initial_instances
  autoscaling_max_instances     = local.standby_autoscaling_max_instances
  scale_out_cpu_threshold       = local.standby_scale_out_cpu_threshold
  scale_in_cpu_threshold        = local.standby_scale_in_cpu_threshold
  lb_attachment                 = module.lb_standby.lb_attachment
  user_data                     = local.standby_user_data
  defined_tags                  = local.defined_tags
  freeform_tags                 = merge(local.freeform_tags, { region_role = "standby" })
}

module "dns_steering" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-dns-steering.git?ref=v0.1.0"

  providers = {
    oci = oci.home
  }

  compartment_id        = local.compartment_ocid
  display_name          = local.dns_policy_name
  template              = "FAILOVER"
  zone_name             = local.dns_zone_name
  domain_name           = local.dns_domain_name
  create_anchor_record  = local.anchor_record != null
  anchor_record_address = local.anchor_record
  ttl                   = 30
  defined_tags          = local.defined_tags
  freeform_tags         = local.freeform_tags

  answers = [
    {
      name  = "primary-${local.primary_region}"
      rtype = "A"
      rdata = module.lb_primary.load_balancer_public_ips[0]
      pool  = "primary"
    },
    {
      name  = "standby-${local.standby_region}"
      rtype = "A"
      rdata = module.lb_standby.load_balancer_public_ips[0]
      pool  = "standby"
    }
  ]

  health_check = {
    display_name = "${local.project_name}-http-monitor"
    targets = [
      module.lb_primary.load_balancer_public_ips[0],
      module.lb_standby.load_balancer_public_ips[0],
    ]
  }
}
