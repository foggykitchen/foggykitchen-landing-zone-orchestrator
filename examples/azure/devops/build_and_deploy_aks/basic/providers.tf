terraform {
  required_version = ">= 1.6.0"

  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0, < 5.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "= 3.10.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "= 1.16.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  features {}
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azuredevops" {
  org_service_url = var.organization_url
  use_cli         = true
}
