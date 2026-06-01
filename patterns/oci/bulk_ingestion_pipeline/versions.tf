terraform {
  required_version = ">= 1.6.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
    oci = {
      source                = "oracle/oci"
      version               = ">= 6.21.0"
      configuration_aliases = [oci.home]
    }
  }
}
