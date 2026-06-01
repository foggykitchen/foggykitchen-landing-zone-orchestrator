terraform {
  required_version = ">= 1.8.0"

  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = ">= 6.21.0"
      configuration_aliases = [oci.home, oci.standby]
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
  }
}
