# Synthetic inputs and mocked providers; plan only, no Azure credentials.
mock_provider "azurerm" {
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet" }
  }
  # OpenTofu mocks apply per resource type; Bastion requires this reserved name.
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/AzureBastionSubnet" }
  }
  mock_resource "azurerm_public_ip" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/publicIPAddresses/mock-pip" }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/networkSecurityGroups/mock-nsg" }
  }
  mock_resource "azurerm_nat_gateway" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/natGateways/mock-nat" }
  }
  mock_resource "azurerm_route_table" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/routeTables/mock-route" }
  }
  mock_resource "azurerm_network_interface" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/networkInterfaces/mock-nic" }
  }
  mock_resource "azurerm_private_dns_zone" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/mock.postgres.database.azure.com" }
  }
  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/mock-pg" }
  }
}

variables {
  subscription_id           = "00000000-0000-0000-0000-000000000001"
  tenant_id                 = "00000000-0000-0000-0000-000000000002"
  admin_ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDF0vLoqzu0h5ueltu/m5920xNdiORUPstx36miYiRj52qedPrswE33ZFefNT9yTcmsNPvXyav087yZKDYuRuumGJ84WYvQuJcAvotLigvrYn+N3fwlagzRlHdng5LtUGNG/Ys7tyzurw+M+2GmoeKSvhmshqXqlA0bUyIT0LoWdup60h4+81rBjOIXpKt793R6gcJjpMSN6JxSd22npGnce6/o87b6THQP79C1ZwFnTqPTbC/v/4oNpj2rTkmOLDDldWLR4TqaeWoaSvH2m/jAV3/XGfwJgMfD30tHmHDulZaKVLFbQD1JIqBardgbnVQE6Y/rUv8YftBzYjPUxp5t mock-only-release-test"
  postgresql_admin_password = "MockOnlyPassword123!"
}

run "azure_plan" {
  command = plan

  assert {
    condition     = output.postgresql_private_access.public_network_access_enabled == false && output.postgresql_private_access.private_endpoint_id == null && output.validation_host.public_ip == null
    error_message = "Delegated PostgreSQL and its validation host must remain private without a Private Endpoint."
  }
}
