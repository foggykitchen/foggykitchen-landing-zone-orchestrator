# Plan only: synthetic inputs and mocked providers; no tenancy access.
mock_provider "oci" {
  mock_resource "oci_load_balancer_load_balancer" {
    defaults = { ip_address_details = [{ ip_address = "192.0.2.10", is_public = true, reserved_ip = [] }] }
  }

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

}
mock_provider "oci" {
  mock_resource "oci_load_balancer_load_balancer" {
    defaults = { ip_address_details = [{ ip_address = "192.0.2.10", is_public = true, reserved_ip = [] }] }
  }
  alias = "home"

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

}
mock_provider "oci" {
  mock_resource "oci_load_balancer_load_balancer" {
    defaults = { ip_address_details = [{ ip_address = "192.0.2.10", is_public = true, reserved_ip = [] }] }
  }
  alias = "standby"

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

}
mock_provider "local" {}

variables {
  tenancy_ocid         = "ocid1.tenancy.oc1..mock"
  user_ocid            = "ocid1.user.oc1..mock"
  fingerprint          = "mock-value"
  private_key_path     = "unused-by-mock"
  iam_home_region      = "eu-frankfurt-1"
  primary_region       = "eu-frankfurt-1"
  standby_region       = "eu-amsterdam-1"
  compartment_ocid     = "ocid1.compartment.oc1..mock"
  admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQMockOnly"
}

run "oci9_plan" {
  command = plan

  assert {
    condition     = output.primary_site.region != output.standby_site.region && length(output.dns_failover.steering_policy) > 0
    error_message = "The example must preserve its composed resources and output contract."
  }
}
