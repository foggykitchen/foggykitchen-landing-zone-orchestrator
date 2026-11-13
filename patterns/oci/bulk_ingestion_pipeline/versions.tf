terraform {
  required_version = ">= 1.11.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
    oci = {
      source                = "oracle/oci"
      version               = ">= 9.12.1, < 10.0.0"
      configuration_aliases = [oci.home]
    }
  }
}
