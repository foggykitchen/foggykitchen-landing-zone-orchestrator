# Plan only: synthetic inputs and mocked providers; no tenancy access.
mock_provider "oci" {

  # Synthetic data only; no live cloud reads.
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
  mock_data "oci_identity_regions" {
    defaults = { "id" = "MOCK_OCID_REGIONS", "regions" = [{ "key" = "FRA", "name" = "eu-frankfurt-1" }, { "key" = "AMS", "name" = "eu-amsterdam-1" }] }
  }
  mock_data "oci_objectstorage_namespace" {
    defaults = { namespace = "mock-namespace" }
  }

}

variables {
  tenancy_ocid                       = "ocid1.tenancy.oc1..mock"
  user_ocid                          = "ocid1.user.oc1..mock"
  fingerprint                        = "mock-value"
  private_key_path                   = "unused-by-mock"
  region                             = "eu-frankfurt-1"
  iam_home_region                    = "eu-frankfurt-1"
  compartment_ocid                   = "ocid1.compartment.oc1..mock"
  github_pat_secret_ocid             = "ocid1.github_pat_secret.oc1..mock"
  github_pat_secret_compartment_ocid = "ocid1.github_pat_secret_compartment.oc1..mock"
  availability_domain                = "mock-value"
}

run "oci9_plan" {
  command = plan

  assert {
    condition     = length(output.build_pipeline_ids) == 1 && length(output.repository_ids) > 0
    error_message = "The example must preserve its composed resources and output contract."
  }
}
