# Plan only: synthetic inputs and mocked providers; no tenancy access.
mock_provider "oci" {

  # Synthetic data only; no live cloud reads.
  mock_data "oci_core_services" {
    defaults = { services = [{ "cidr_block" : "all-fra-services-in-oracle-services-network", "description" : "mock-value", "id" : "mock-service", "name" : "All FRA Services In Oracle Services Network" }] }
  }
  mock_data "oci_identity_regions" {
    defaults = { "id" = "MOCK_OCID_REGIONS", "regions" = [{ "key" = "FRA", "name" = "eu-frankfurt-1" }, { "key" = "AMS", "name" = "eu-amsterdam-1" }] }
  }
  mock_data "oci_objectstorage_namespace" {
    defaults = { namespace = "mock-namespace" }
  }

}
mock_provider "oci" {
  alias = "home"

  # Synthetic data only; no live cloud reads.
  mock_data "oci_core_services" {
    defaults = { services = [{ "cidr_block" : "all-fra-services-in-oracle-services-network", "description" : "mock-value", "id" : "mock-service", "name" : "All FRA Services In Oracle Services Network" }] }
  }
  mock_data "oci_identity_regions" {
    defaults = { "id" = "MOCK_OCID_REGIONS", "regions" = [{ "key" = "FRA", "name" = "eu-frankfurt-1" }, { "key" = "AMS", "name" = "eu-amsterdam-1" }] }
  }
  mock_data "oci_objectstorage_namespace" {
    defaults = { namespace = "mock-namespace" }
  }

}
mock_provider "local" {}
mock_provider "null" {}
mock_provider "random" {}

variables {
  tenancy_ocid          = "ocid1.tenancy.oc1..mock"
  user_ocid             = "ocid1.user.oc1..mock"
  fingerprint           = "mock-value"
  private_key_path      = "unused-by-mock"
  compartment_ocid      = "ocid1.compartment.oc1..mock"
  region                = "eu-frankfurt-1"
  iam_home_region       = "eu-frankfurt-1"
  ocir_user_name        = "mock-value"
  ocir_user_password    = "MockOnlyPassword123!"
  adb_admin_password    = "MockOnlyPassword123!"
  adb_app_user_password = "MockOnlyPassword123!"
}

run "oci9_plan" {
  command = plan

  assert {
    condition     = length(output.function_ids) == 3 && length(output.streaming.stream_ids) > 0
    error_message = "The example must preserve its composed resources and output contract."
  }
}
