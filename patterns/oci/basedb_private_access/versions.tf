terraform {
  required_version = ">= 1.11.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 9.12.1, < 10.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0, < 1.0.0"
    }
  }
}
