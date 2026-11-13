# Plan only: synthetic inputs and mocked providers; no tenancy access.
mock_provider "oci" {

  # Synthetic data only; no live cloud reads.
  mock_data "oci_containerengine_addon_options" {
    defaults = { "addon_options" = [{ "addon_group" = "mock-value", "addon_schema_version" = "mock-value", "defined_tags" = {}, "description" = "mock-value", "freeform_tags" = {}, "is_essential" = false, "name" = "compatibility", "state" = "AVAILABLE", "system_tags" = {}, "time_created" = "mock-value", "versions" = [{ "configurations" = [], "description" = "mock-value", "kubernetes_version_filters" = [], "status" = "mock-value", "version_number" = "mock-value" }] }], "id" = "MOCK_OCID_OPTIONS" }
  }
  mock_data "oci_containerengine_addons" {
    defaults = { "addons" = [{ "addon_error" = [{ "code" = "mock-value", "message" = "mock-value", "status" = "mock-value" }], "addon_name" = "mock-value", "cluster_id" = "MOCK_OCID_MOCK", "configurations" = [{ "key" = "FRA", "value" = "mock-value" }], "current_installed_version" = "mock-value", "override_existing" = false, "remove_addon_resources_on_delete" = false, "state" = "AVAILABLE", "time_created" = "mock-value", "version" = "mock-value" }], "id" = "MOCK_OCID_ADDONS" }
  }
  mock_data "oci_containerengine_cluster_kube_config" {
    defaults = { "content" = "apiVersion: v1\nclusters: []\nusers: []\ncontexts: []\n", "id" = "MOCK_OCID_CONFIG" }
  }
  mock_data "oci_containerengine_cluster_option" {
    defaults = { "cluster_pod_network_options" = [{ "cni_type" = "mock-value" }], "id" = "MOCK_OCID_OPTION", "kubernetes_versions" = ["mock-value"] }
  }
  mock_data "oci_containerengine_node_pool_option" {
    defaults = { "id" = "MOCK_OCID_OPTION", "images" = ["mock-value"], "kubernetes_versions" = ["mock-value"], "shapes" = ["mock-value"], "sources" = [{ "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-2025.04.30-0-OKE-1.31.1", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-aarch64-2025.04.30-0-OKE-1.31.1", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-Gen2-GPU-2025.04.30-0-OKE-1.31.1", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-2025.04.30-0-OKE-1.35.2", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-aarch64-2025.04.30-0-OKE-1.35.2", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-Gen2-GPU-2025.04.30-0-OKE-1.35.2", "source_type" = "IMAGE" }] }
  }
  mock_data "oci_core_services" {
    defaults = { services = [{ "cidr_block" : "all-fra-services-in-oracle-services-network", "description" : "mock-value", "id" : "mock-service", "name" : "All FRA Services In Oracle Services Network" }] }
  }
  mock_data "oci_identity_availability_domains" {
    defaults = { availability_domains = [{ "compartment_id" : "ocid1.compartment.oc1..mock", "id" : "mock-ad", "name" : "MOCK:EU-FRANKFURT-1-AD-1" }] }
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
  mock_data "oci_containerengine_addon_options" {
    defaults = { "addon_options" = [{ "addon_group" = "mock-value", "addon_schema_version" = "mock-value", "defined_tags" = {}, "description" = "mock-value", "freeform_tags" = {}, "is_essential" = false, "name" = "compatibility", "state" = "AVAILABLE", "system_tags" = {}, "time_created" = "mock-value", "versions" = [{ "configurations" = [], "description" = "mock-value", "kubernetes_version_filters" = [], "status" = "mock-value", "version_number" = "mock-value" }] }], "id" = "MOCK_OCID_OPTIONS" }
  }
  mock_data "oci_containerengine_addons" {
    defaults = { "addons" = [{ "addon_error" = [{ "code" = "mock-value", "message" = "mock-value", "status" = "mock-value" }], "addon_name" = "mock-value", "cluster_id" = "MOCK_OCID_MOCK", "configurations" = [{ "key" = "FRA", "value" = "mock-value" }], "current_installed_version" = "mock-value", "override_existing" = false, "remove_addon_resources_on_delete" = false, "state" = "AVAILABLE", "time_created" = "mock-value", "version" = "mock-value" }], "id" = "MOCK_OCID_ADDONS" }
  }
  mock_data "oci_containerengine_cluster_kube_config" {
    defaults = { "content" = "apiVersion: v1\nclusters: []\nusers: []\ncontexts: []\n", "id" = "MOCK_OCID_CONFIG" }
  }
  mock_data "oci_containerengine_cluster_option" {
    defaults = { "cluster_pod_network_options" = [{ "cni_type" = "mock-value" }], "id" = "MOCK_OCID_OPTION", "kubernetes_versions" = ["mock-value"] }
  }
  mock_data "oci_containerengine_node_pool_option" {
    defaults = { "id" = "MOCK_OCID_OPTION", "images" = ["mock-value"], "kubernetes_versions" = ["mock-value"], "shapes" = ["mock-value"], "sources" = [{ "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-2025.04.30-0-OKE-1.31.1", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-aarch64-2025.04.30-0-OKE-1.31.1", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-Gen2-GPU-2025.04.30-0-OKE-1.31.1", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-2025.04.30-0-OKE-1.35.2", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-aarch64-2025.04.30-0-OKE-1.35.2", "source_type" = "IMAGE" }, { "image_id" = "MOCK_OCID_IMAGE", "source_name" = "Oracle-Linux-8.10-Gen2-GPU-2025.04.30-0-OKE-1.35.2", "source_type" = "IMAGE" }] }
  }
  mock_data "oci_core_services" {
    defaults = { services = [{ "cidr_block" : "all-fra-services-in-oracle-services-network", "description" : "mock-value", "id" : "mock-service", "name" : "All FRA Services In Oracle Services Network" }] }
  }
  mock_data "oci_identity_availability_domains" {
    defaults = { availability_domains = [{ "compartment_id" : "ocid1.compartment.oc1..mock", "id" : "mock-ad", "name" : "MOCK:EU-FRANKFURT-1-AD-1" }] }
  }
  mock_data "oci_identity_regions" {
    defaults = { "id" = "MOCK_OCID_REGIONS", "regions" = [{ "key" = "FRA", "name" = "eu-frankfurt-1" }, { "key" = "AMS", "name" = "eu-amsterdam-1" }] }
  }
  mock_data "oci_objectstorage_namespace" {
    defaults = { namespace = "mock-namespace" }
  }

}
mock_provider "tls" {}

variables {
  tenancy_ocid                       = "ocid1.tenancy.oc1..mock"
  user_ocid                          = "ocid1.user.oc1..mock"
  fingerprint                        = "mock-value"
  private_key_path                   = "unused-by-mock"
  compartment_ocid                   = "ocid1.compartment.oc1..mock"
  region                             = "eu-frankfurt-1"
  iam_home_region                    = "eu-frankfurt-1"
  github_pat_secret_ocid             = "ocid1.github_pat_secret.oc1..mock"
  github_pat_secret_compartment_ocid = "ocid1.github_pat_secret_compartment.oc1..mock"
  ocir_user_name                     = "mock-value"
  ocir_user_password                 = "MockOnlyPassword123!"
}

run "oci9_plan" {
  command = plan

  assert {
    condition     = length(output.build_pipeline_ids) == 1 && length(output.deploy_pipeline_ids) == 1
    error_message = "The example must preserve its composed resources and output contract."
  }
}
