terraform {
  required_version = ">= 1.8.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.21.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}
