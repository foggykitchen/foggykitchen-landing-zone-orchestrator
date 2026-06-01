terraform {
  required_version = ">= 1.3.0"

  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = ">= 6.21.0"
      configuration_aliases = [oci.home]
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
  }
}
