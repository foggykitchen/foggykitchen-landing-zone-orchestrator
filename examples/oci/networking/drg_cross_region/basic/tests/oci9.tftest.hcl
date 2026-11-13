# Plan only: synthetic inputs and mocked providers; no tenancy access.
mock_provider "oci" {

  # Synthetic data only; no live cloud reads.
  mock_data "oci_core_services" {
    defaults = { services = [{ "cidr_block" : "all-fra-services-in-oracle-services-network", "description" : "mock-value", "id" : "mock-service", "name" : "All FRA Services In Oracle Services Network" }] }
  }

}
mock_provider "oci" {
  alias = "peer"

  # Synthetic data only; no live cloud reads.
  mock_data "oci_core_services" {
    defaults = { services = [{ "cidr_block" : "all-fra-services-in-oracle-services-network", "description" : "mock-value", "id" : "mock-service", "name" : "All FRA Services In Oracle Services Network" }] }
  }

}

variables {
  user_ocid        = "ocid1.user.oc1..mock"
  fingerprint      = "mock-value"
  private_key_path = "unused-by-mock"
}

run "oci9_plan" {
  command = plan

  assert {
    condition     = length(output.home_remote_peering_connection_ids) > 0 && length(output.peer_remote_peering_connection_ids) > 0
    error_message = "The example must preserve its composed resources and output contract."
  }
}
