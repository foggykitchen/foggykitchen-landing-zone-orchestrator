module "vcn" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=v0.1.0"

  compartment_ocid = local.compartment_ocid
  name             = "${local.project_name}-vcn"
  vcn_cidr_blocks  = [local.vcn_cidr]
  dns_label        = "fkadbpriv"

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true

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
          destination        = "all-services"
          destination_type   = "SERVICE_CIDR_BLOCK"
          network_entity_key = "service_gateway"
        }
      ]
    }
  }

  security_lists = {
    client_public = {
      ingress_rules = [
        {
          protocol = "6"
          source   = local.client_ssh_ingress_cidr
          tcp_options = {
            min = 22
            max = 22
          }
        }
      ]
      egress_rules = [
        {
          protocol    = "all"
          destination = "0.0.0.0/0"
        }
      ]
    }
    adb_private = {
      ingress_rules = [
        {
          protocol = "6"
          source   = local.client_subnet_cidr
          tcp_options = {
            min = 1522
            max = 1522
          }
        }
      ]
      egress_rules = [
        {
          protocol    = "all"
          destination = "0.0.0.0/0"
        }
      ]
    }
  }

  subnets = {
    client_public = {
      cidr_block                 = local.client_subnet_cidr
      display_name               = "${local.project_name}-client-public"
      dns_label                  = "clientpub"
      route_table_key            = "public"
      security_list_keys         = ["client_public"]
      prohibit_public_ip_on_vnic = false
    }
    adb_private = {
      cidr_block                 = local.adb_subnet_cidr
      display_name               = "${local.project_name}-adb-private"
      dns_label                  = "adbpriv"
      route_table_key            = "private"
      security_list_keys         = ["adb_private"]
      prohibit_internet_ingress  = true
      prohibit_public_ip_on_vnic = true
    }
  }

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}

module "adb_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-nsg.git?ref=v0.1.0"

  name             = "${local.project_name}-adb-nsg"
  compartment_ocid = local.compartment_ocid
  vcn_id           = module.vcn.vcn_id

  security_rules = [
    {
      name        = "allow-adb-sqlnet-ingress"
      direction   = "INGRESS"
      protocol    = "6"
      source      = local.client_subnet_cidr
      source_type = "CIDR_BLOCK"
      tcp_options = {
        destination_port_range = {
          min = 1522
          max = 1522
        }
      }
      description = "Allow SQL*Net access from the validation host subnet."
    },
    {
      name             = "allow-vcn-egress"
      direction        = "EGRESS"
      protocol         = "all"
      destination      = local.vcn_cidr
      destination_type = "CIDR_BLOCK"
      description      = "Allow outbound traffic from the ADB private endpoint to the VCN."
    }
  ]

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}

module "adb" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-adb.git?ref=v1.4"

  compartment_ocid                      = local.compartment_ocid
  adb_password                          = local.adb_admin_password
  adb_database_db_name                  = local.adb_database_name
  adb_database_display_name             = local.adb_display_name
  adb_database_db_workload              = local.adb_db_workload
  adb_free_tier                         = local.adb_free_tier
  adb_database_cpu_core_count           = local.adb_cpu_core_count
  adb_database_data_storage_size_in_tbs = local.adb_storage_size_in_tbs
  adb_private_endpoint                  = true
  adb_private_endpoint_label            = local.adb_private_endpoint_label
  is_auto_scaling_enabled               = local.adb_autoscaling_enabled
  use_existing_vcn                      = true
  adb_subnet_id                         = module.vcn.subnet_ids["adb_private"]
  adb_nsg_id                            = module.adb_nsg.nsg_id

  defined_tags = local.defined_tags
}

module "client_host" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-compute.git?ref=v0.2.2"

  name             = local.client_name
  tenancy_ocid     = local.tenancy_ocid
  compartment_ocid = local.compartment_ocid
  subnet_id        = module.vcn.subnet_ids["client_public"]

  deployment_mode          = "instance"
  shape                    = local.client_shape
  operating_system         = local.client_operating_system
  operating_system_version = local.client_operating_system_version
  shape_config             = local.client_shape_config

  assign_public_ip    = true
  ssh_authorized_keys = local.client_ssh_authorized_keys
  user_data           = local.client_user_data

  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}
