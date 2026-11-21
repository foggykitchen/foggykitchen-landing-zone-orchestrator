data "oci_identity_availability_domains" "this" {
  compartment_id = local.tenancy_ocid
}
data "oci_core_services" "osn" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "terraform_data" "guardrails" {
  lifecycle {
    precondition {
      condition = length(local.bastion_allow_list) > 0 && alltrue([
        for cidr in local.bastion_allow_list : try(can(cidrnetmask(cidr)) && tonumber(split("/", cidr)[1]) > 0, false)
      ])
      error_message = "Bastion requires a nonempty IPv4 CIDR allow list; /0 is forbidden."
    }
    precondition {
      condition     = local.bastion_session_ttl >= 1800 && local.bastion_session_ttl <= 10800
      error_message = "Bastion session TTL must be between 1800 and 10800 seconds."
    }
    precondition {
      condition     = local.basedb.admin_password == "__runtime_password__" && length(local.client_ssh_keys) == 1
      error_message = "Use the runtime password placeholder and exactly one shared client SSH key."
    }
  }
}

module "vcn" {
  source                  = "git::https://github.com/foggykitchen/terraform-oci-fk-vcn.git?ref=v0.3.0"
  compartment_ocid        = local.compartment_ocid
  name                    = "${local.project_name}-vcn"
  dns_label               = "fkbasedb"
  vcn_cidr_blocks         = [local.vcn_cidr]
  create_internet_gateway = false
  create_nat_gateway      = true
  create_service_gateway  = true
  route_tables = {
    private = {
      route_rules = [
        { destination = "0.0.0.0/0", destination_type = "CIDR_BLOCK", network_entity_key = "nat_gateway" },
        { destination = "all-services", destination_type = "SERVICE_CIDR_BLOCK", network_entity_key = "service_gateway" }
      ]
    }
  }
  security_lists = {
    nsg_only = { display_name = "NSG-only", ingress_rules = [], egress_rules = [] }
    # Bastion's service-managed endpoint has no workload NSG attachment.
    # Permit only its two target paths; workload ingress stays in NSGs.
    bastion_endpoint = {
      display_name  = "Bastion endpoint egress"
      ingress_rules = []
      egress_rules = [
        { protocol = "6", destination = local.client_subnet_cidr, destination_type = "CIDR_BLOCK", tcp_options = { min = 22, max = 22 } },
        { protocol = "6", destination = local.db_subnet_cidr, destination_type = "CIDR_BLOCK", tcp_options = { min = 1521, max = 1521 } }
      ]
    }
  }
  subnets       = local.subnets
  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
  depends_on    = [terraform_data.guardrails]
}
module "db_nsg" {
  source           = "git::https://github.com/foggykitchen/terraform-oci-fk-nsg.git?ref=v0.2.0"
  name             = "${local.project_name}-db-nsg"
  compartment_ocid = local.compartment_ocid
  vcn_id           = module.vcn.vcn_id
  security_rules   = local.db_security_rules
  defined_tags     = local.defined_tags
  freeform_tags    = local.freeform_tags
}
module "client_nsg" {
  source           = "git::https://github.com/foggykitchen/terraform-oci-fk-nsg.git?ref=v0.2.0"
  name             = "${local.project_name}-client-nsg"
  compartment_ocid = local.compartment_ocid
  vcn_id           = module.vcn.vcn_id
  security_rules   = local.client_security_rules
  defined_tags     = local.defined_tags
  freeform_tags    = local.freeform_tags
}
module "client_host" {
  source                   = "git::https://github.com/foggykitchen/terraform-oci-fk-compute.git?ref=v0.3.0"
  name                     = local.client_name
  tenancy_ocid             = local.tenancy_ocid
  compartment_ocid         = local.compartment_ocid
  availability_domain      = local.availability_domain
  subnet_id                = module.vcn.subnet_ids["client_private"]
  nsg_ids                  = [module.client_nsg.nsg_id]
  deployment_mode          = "instance"
  shape                    = try(local.client.shape, "VM.Standard.E5.Flex")
  operating_system         = try(local.client.operating_system, "Oracle Linux")
  operating_system_version = try(local.client.operating_system_version, "9")
  shape_config             = try(local.client.shape_config, { ocpus = 1, memory_in_gbs = 8 })
  assign_public_ip         = local.client_assign_public_ip
  ssh_authorized_keys      = local.client_ssh_keys
  user_data                = local.client_user_data
  agent_config = {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
    plugins_config           = [{ name = "Bastion", desired_state = "ENABLED" }]
  }
  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}
resource "time_sleep" "wait_for_bastion_plugin" {
  depends_on      = [module.client_host]
  create_duration = "600s"
  triggers        = { instance_id = module.client_host.instance_id }
}
module "bastion" {
  source                                     = "git::https://github.com/foggykitchen/terraform-oci-fk-bastion-service.git?ref=v0.2.0"
  depends_on                                 = [time_sleep.wait_for_bastion_plugin]
  name                                       = try(local.bastion.name, "fkbasedbbastionservice")
  compartment_ocid                           = local.compartment_ocid
  target_subnet_id                           = module.vcn.subnet_ids["client_private"]
  client_cidr_block_allow_list               = local.bastion_allow_list
  max_session_ttl_in_seconds                 = 10800
  create_session                             = local.bastion_create_session
  session_name                               = "${local.project_name}-client"
  session_type                               = "MANAGED_SSH"
  session_ttl_in_seconds                     = local.bastion_session_ttl
  ssh_public_key                             = local.client_ssh_keys[0]
  target_resource_id                         = module.client_host.instance_id
  target_resource_private_ip_address         = module.client_host.instance_private_ip
  target_resource_port                       = 22
  target_resource_operating_system_user_name = "opc"
  defined_tags                               = local.defined_tags
  freeform_tags                              = local.freeform_tags
}
module "basedb" {
  source                  = "git::https://github.com/foggykitchen/terraform-oci-fk-basedb.git?ref=v0.1.0"
  providers               = { oci = oci, oci.target = oci }
  role                    = "PRIMARY"
  compartment_id          = local.compartment_ocid
  availability_domain     = local.availability_domain
  fault_domains           = try(local.basedb.fault_domains, null)
  subnet_id               = module.vcn.subnet_ids["db_private"]
  nsg_ids                 = [module.db_nsg.nsg_id]
  display_name            = local.basedb.display_name
  hostname                = local.basedb.hostname
  shape                   = try(local.basedb.shape, "VM.BaseDB.x86")
  compute_model           = try(local.basedb.compute_model, "ECPU")
  compute_count           = try(local.basedb.compute_count, 4)
  data_storage_size_in_gb = try(local.basedb.data_storage_size_in_gb, 256)
  database_edition        = try(local.basedb.database_edition, "STANDARD_EDITION")
  license_model           = try(local.basedb.license_model, "LICENSE_INCLUDED")
  database_name           = local.basedb.database_name
  pdb_name                = local.basedb.pdb_name
  database_version        = local.basedb.database_version
  auto_backup_enabled     = try(local.basedb.auto_backup_enabled, false)
  admin_password          = var.basedb_admin_password
  ssh_public_keys         = local.client_ssh_keys
  defined_tags            = local.defined_tags
  freeform_tags           = local.freeform_tags
  depends_on              = [module.db_nsg]
}
