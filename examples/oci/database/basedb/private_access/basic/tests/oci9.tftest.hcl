# Plan only: synthetic inputs and mocked providers; no tenancy access.
mock_provider "oci" {

  # Synthetic data only; no live cloud reads.
  mock_data "oci_core_services" {
    defaults = { services = [{ "cidr_block" : "all-fra-services-in-oracle-services-network", "description" : "mock-value", "id" : "mock-service", "name" : "All FRA Services In Oracle Services Network" }] }
  }
  mock_data "oci_identity_availability_domains" {
    defaults = { availability_domains = [{ "compartment_id" : "ocid1.compartment.oc1..mock", "id" : "mock-ad", "name" : "MOCK:EU-FRANKFURT-1-AD-1" }] }
  }
  mock_data "oci_core_images" {
    defaults = { images = [{ "agent_features" : [], "base_image_id" : "mock-value", "billable_size_in_gbs" : "mock-value", "compartment_id" : "mock-value", "create_image_allowed" : false, "defined_tags" : {}, "display_name" : "Mock Oracle Linux", "freeform_tags" : {}, "id" : "ocid1.image.oc1..mock", "image_source_details" : [], "instance_id" : "mock-value", "launch_mode" : "mock-value", "launch_options" : [], "listing_type" : "mock-value", "operating_system" : "Oracle Linux", "operating_system_version" : "9", "size_in_mbs" : "mock-value", "state" : "AVAILABLE", "time_created" : "mock-value" }] }
  }
  mock_data "oci_core_vnic_attachments" {
    defaults = { vnic_attachments = [{ "availability_domain" : "mock-value", "compartment_id" : "mock-value", "create_vnic_details" : [], "display_name" : "mock-value", "id" : "mock-vnic-attachment", "instance_id" : "mock-instance", "nic_index" : 1, "state" : "ATTACHED", "subnet_id" : "mock-value", "time_created" : "mock-value", "vlan_id" : "mock-value", "vlan_tag" : 1, "vnic_id" : "mock-vnic" }] }
  }
  mock_data "oci_core_private_ips" {
    defaults = { private_ips = [{ "availability_domain" : "mock-value", "cidr_prefix_length" : 1, "compartment_id" : "mock-value", "defined_tags" : {}, "display_name" : "mock-value", "freeform_tags" : {}, "hostname_label" : "mock-value", "id" : "mock-private-ip", "ip_address" : "10.0.0.10", "ip_state" : "mock-value", "ipv4subnet_cidr_at_creation" : "mock-value", "is_primary" : false, "is_reserved" : false, "lifetime" : "mock-value", "route_table_id" : "mock-value", "subnet_id" : "mock-value", "time_created" : "mock-value", "vlan_id" : "mock-value", "vnic_id" : "mock-vnic" }] }
  }

  mock_data "oci_database_db_nodes" {
    defaults = { "db_nodes" : [{ "additional_details" : "mock-value", "backup_ip_id" : "mock-value", "backup_ipv6id" : "mock-value", "backup_vnic2id" : "mock-value", "backup_vnic_id" : "mock-value", "compute_count" : 1, "compute_model" : "mock-value", "cpu_core_count" : 1, "db_node_id" : "mock-value", "db_node_storage_size_in_gbs" : 1, "db_server_id" : "mock-value", "db_system_id" : "mock-value", "defined_tags" : {}, "fault_domain" : "mock-value", "freeform_tags" : {}, "host_ip_id" : "mock-value", "host_ipv6id" : "mock-value", "hostname" : "mock-value", "id" : "ocid1.dbnode.oc1..mock", "is_os_patch_reboot_required" : false, "lifecycle_details" : "mock-value", "maintenance_type" : "mock-value", "memory_size_in_gbs" : 1, "software_storage_size_in_gb" : 1, "state" : "AVAILABLE", "system_tags" : {}, "time_created" : "mock-value", "time_maintenance_window_end" : "mock-value", "time_maintenance_window_start" : "mock-value", "total_cpu_core_count" : 1, "vnic2id" : "mock-value", "vnic_id" : "ocid1.vnic.oc1..mock" }] }
  }
  mock_data "oci_database_database" {
    defaults = { db_home_id = "ocid1.dbhome.oc1..mock", state = "AVAILABLE", connection_strings = [] }
  }
  mock_data "oci_core_vnic" {
    defaults = { private_ip_address = "10.130.20.10", public_ip_address = null }
  }
  mock_resource "oci_core_subnet" {
    defaults = { id = "ocid1.subnet.oc1..mock" }
  }
  mock_resource "oci_core_instance" {
    defaults = { id = "ocid1.instance.oc1..mock", private_ip = "10.130.10.10", public_ip = null }
  }
  mock_resource "oci_bastion_bastion" {
    defaults = { id = "ocid1.bastion.oc1..mock" }
  }
  mock_resource "oci_bastion_session" {
    defaults = { id = "ocid1.bastionsession.oc1..mock", ssh_metadata = { command = "ssh MOCK_SESSION_COMMAND" } }
  }
}
mock_provider "tls" {}
mock_provider "time" {}

variables {
  tenancy_ocid          = "ocid1.tenancy.oc1..mock"
  compartment_ocid      = "ocid1.compartment.oc1..mock"
  user_ocid             = "ocid1.user.oc1..mock"
  fingerprint           = "mock"
  private_key_path      = "unused-by-mock"
  workload_region       = "eu-frankfurt-1"
  database_version      = "23.26.4.0.0"
  basedb_admin_password = "MockOnlyPassword123!"
  operator_client_cidr  = "203.0.113.10/32"
  admin_ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQMockOnly"
}
run "private_primary" {
  command = plan
  assert {
    condition     = length(output.network.vcn_id) > 0 && length(output.basedb_private_access.db_system_id) > 0 && length(output.bastion.bastion_id) > 0
    error_message = "VCN, BaseDB and Bastion must all be composed."
  }
  assert {
    condition     = output.basedb_private_access.db_subnet_id == output.network.db_subnet_id && length(output.basedb_private_access.db_nsg_id) > 0
    error_message = "The database output must retain the private subnet and NSG association."
  }
}
run "reject_public_operator" {
  command = plan
  variables { operator_client_cidr = "0.0.0.0/0" }
  expect_failures = [var.operator_client_cidr]
}
run "generated_ssh_key" {
  command = plan
  variables { admin_ssh_public_key = "" }
  assert {
    condition     = length(tls_private_key.generated) == 1
    error_message = "An omitted key must generate one lab key without making topology unplannable."
  }
}
run "pattern_security" {
  command = plan
  module { source = "../../../../../../patterns/oci/basedb_private_access" }
  variables {
    payload_file = "./landing-zone.yaml"
    payload_template_vars = {
      tenancy_ocid         = "ocid1.tenancy.oc1..mock"
      compartment_ocid     = "ocid1.compartment.oc1..mock"
      workload_region      = "eu-frankfurt-1"
      database_version     = "23.26.4.0.0"
      operator_client_cidr = "203.0.113.10/32"
    }
  }
  assert {
    condition     = try(local.basedb.encryption.kms_key_id, null) == null && try(local.basedb.encryption.vault_id, null) == null && try(local.basedb.encryption.kms_key_version_id, null) == null
    error_message = "The unchanged basic payload must omit all CMK inputs."
  }
  assert {
    condition     = local.client_assign_public_ip == false && alltrue([for subnet in module.vcn.subnets : subnet.prohibit_public_ip_on_vnic && subnet.prohibit_internet_ingress]) && module.vcn.internet_gateway_id == null
    error_message = "The client and database must remain private, with no Internet Gateway."
  }
  assert {
    condition     = length([for rule in local.db_security_rules : rule if try(rule.direction == "INGRESS" && rule.protocol == "6" && rule.tcp_options.destination_port_range.min == 1521 && rule.tcp_options.destination_port_range.max == 1521 && rule.source == local.client_subnet_cidr, false)]) == 1 && alltrue([for rule in local.db_security_rules : try(rule.direction == "INGRESS" && rule.protocol == "6", false) ? rule.source == local.client_subnet_cidr && contains([22, 1521], rule.tcp_options.destination_port_range.min) && rule.tcp_options.destination_port_range.min == rule.tcp_options.destination_port_range.max : try(rule.source != "0.0.0.0/0", true)])
    error_message = "Only the client subnet may initiate SQL*Net to the DB; public ingress is forbidden."
  }
}

run "cmk_primary" {
  command = plan
  module { source = "../../../../../../patterns/oci/basedb_private_access" }
  variables {
    payload_file = "./tests/payload.yaml.tftpl"
    payload_template_vars = {
      payload = yamlencode(merge(yamldecode(templatefile("./landing-zone.yaml", {
        tenancy_ocid          = "ocid1.tenancy.oc1..mock"
        compartment_ocid      = "ocid1.compartment.oc1..mock"
        workload_region       = "eu-frankfurt-1"
        database_version      = "23.26.4.0.0"
        operator_client_cidr  = "203.0.113.10/32"
        basedb_admin_password = "__runtime_password__"
        admin_ssh_public_key  = "__runtime_public_key__"
        })), {
        data = { basedb = {
          display_name     = "mock-primary"
          hostname         = "mockprimary"
          database_name    = "MOCKDB"
          pdb_name         = "MOCKPDB"
          database_version = "23.26.4.0.0"
          admin_password   = "__runtime_password__"
          encryption = {
            kms_key_id         = "ocid1.key.oc1.eu-frankfurt-1.mock"
            vault_id           = "ocid1.vault.oc1.eu-frankfurt-1.mock"
            kms_key_version_id = "ocid1.keyversion.oc1.eu-frankfurt-1.mock"
          }
        } }
      }))
    }
  }
  assert {
    condition     = local.basedb.encryption.kms_key_id == "ocid1.key.oc1.eu-frankfurt-1.mock" && local.basedb.encryption.vault_id == "ocid1.vault.oc1.eu-frankfurt-1.mock"
    error_message = "The CMK payload must retain the selected key and Vault; tests/check-plan.py checks the planned DB resource."
  }
}

run "reject_partial_cmk" {
  command = plan
  module { source = "../../../../../../patterns/oci/basedb_private_access" }
  variables {
    payload_file = "./tests/payload.yaml.tftpl"
    payload_template_vars = {
      payload = yamlencode(merge(yamldecode(templatefile("./landing-zone.yaml", {
        tenancy_ocid          = "ocid1.tenancy.oc1..mock"
        compartment_ocid      = "ocid1.compartment.oc1..mock"
        workload_region       = "eu-frankfurt-1"
        database_version      = "23.26.4.0.0"
        operator_client_cidr  = "203.0.113.10/32"
        basedb_admin_password = "__runtime_password__"
        admin_ssh_public_key  = "__runtime_public_key__"
        })), {
        data = { basedb = {
          display_name     = "mock-primary"
          hostname         = "mockprimary"
          database_name    = "MOCKDB"
          pdb_name         = "MOCKPDB"
          database_version = "23.26.4.0.0"
          admin_password   = "__runtime_password__"
          encryption = {
            kms_key_id         = "ocid1.key.oc1.eu-frankfurt-1.mock"
            vault_id           = null
            kms_key_version_id = null
          }
        } }
      }))
    }
  }
  # Isolate the pattern guardrail from the child module's duplicate pair validation.
  plan_options { target = [terraform_data.guardrails] }
  expect_failures = [terraform_data.guardrails]
}
