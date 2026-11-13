locals {
  payload = yamldecode(file("${path.module}/landing-zone.yaml"))
}

terraform {
  required_version = ">= 1.11.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 9.12.1, < 10.0.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = local.payload.cloud.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = local.payload.cloud.region
}
