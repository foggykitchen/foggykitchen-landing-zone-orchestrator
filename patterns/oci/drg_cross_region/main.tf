module "vcn_home" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=main"

  compartment_ocid = local.compartment_ocid
  name             = local.home.vcn.name
  dns_label        = try(local.home.vcn.dns_label, null)
  vcn_cidr_blocks  = local.home.vcn.cidr_blocks

  create_nat_gateway     = true
  create_service_gateway = true

  extra_network_entity_ids = {
    drg = module.drg_home.drg_id
  }

  route_tables   = local.home_vcn_route_tables
  security_lists = local.home_security_lists
  subnets        = local.home_subnets
  defined_tags   = local.defined_tags
  freeform_tags  = merge(local.freeform_tags, { region_role = "home" })
}

module "drg_home" {
  source = "git::https://github.com/mlinxfeld/terraform-oci-fk-drg.git?ref=main"

  compartment_ocid = local.compartment_ocid
  name             = local.home.drg.name
  display_name     = local.home.drg.name

  vcn_attachments = {
    app = {
      vcn_id              = module.vcn_home.vcn_id
      drg_route_table_key = "from-vcn"
    }
  }

  remote_peering_connections = {
    peer = {
      display_name = local.home.drg.rpc.name
    }
  }

  drg_route_tables = local.home_drg_route_tables
  rpc_attachment_managements = {
    peer = {
      rpc_key             = "peer"
      drg_route_table_key = "from-rpc"
    }
  }
  defined_tags  = local.defined_tags
  freeform_tags = merge(local.freeform_tags, { region_role = "home" })
}

module "vcn_peer" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=main"

  providers = {
    oci = oci.peer
  }

  compartment_ocid = local.compartment_ocid
  name             = local.peer.vcn.name
  dns_label        = try(local.peer.vcn.dns_label, null)
  vcn_cidr_blocks  = local.peer.vcn.cidr_blocks

  create_nat_gateway     = true
  create_service_gateway = true

  extra_network_entity_ids = {
    drg = module.drg_peer.drg_id
  }

  route_tables   = local.peer_vcn_route_tables
  security_lists = local.peer_security_lists
  subnets        = local.peer_subnets
  defined_tags   = local.defined_tags
  freeform_tags  = merge(local.freeform_tags, { region_role = "peer" })
}

module "drg_peer" {
  source = "git::https://github.com/mlinxfeld/terraform-oci-fk-drg.git?ref=main"

  providers = {
    oci = oci.peer
  }

  compartment_ocid = local.compartment_ocid
  name             = local.peer.drg.name
  display_name     = local.peer.drg.name

  vcn_attachments = {
    app = {
      vcn_id              = module.vcn_peer.vcn_id
      drg_route_table_key = "from-vcn"
    }
  }

  remote_peering_connections = {
    peer = {
      display_name     = local.peer.drg.rpc.name
      peer_id          = module.drg_home.remote_peering_connection_ids["peer"]
      peer_region_name = local.cloud.home_region
    }
  }

  drg_route_tables = local.peer_drg_route_tables
  rpc_attachment_managements = {
    peer = {
      rpc_key             = "peer"
      drg_route_table_key = "from-rpc"
    }
  }
  defined_tags  = local.defined_tags
  freeform_tags = merge(local.freeform_tags, { region_role = "peer" })
}
