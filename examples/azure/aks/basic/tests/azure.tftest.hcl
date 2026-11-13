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
mock_provider "null" {}
mock_provider "time" {}

variables {
  subscription_id      = "00000000-0000-0000-0000-000000000001"
  tenant_id            = "00000000-0000-0000-0000-000000000002"
  admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDF0vLoqzu0h5ueltu/m5920xNdiORUPstx36miYiRj52qedPrswE33ZFefNT9yTcmsNPvXyav087yZKDYuRuumGJ84WYvQuJcAvotLigvrYn+N3fwlagzRlHdng5LtUGNG/Ys7tyzurw+M+2GmoeKSvhmshqXqlA0bUyIT0LoWdup60h4+81rBjOIXpKt793R6gcJjpMSN6JxSd22npGnce6/o87b6THQP79C1ZwFnTqPTbC/v/4oNpj2rTkmOLDDldWLR4TqaeWoaSvH2m/jAV3/XGfwJgMfD30tHmHDulZaKVLFbQD1JIqBardgbnVQE6Y/rUv8YftBzYjPUxp5t mock-only-release-test"
}

run "azure_plan" {
  command = plan

  assert {
    condition     = output.jump_host.public_ip == null && output.network.node_subnet_cidr != output.network.jump_subnet_cidr
    error_message = "AKS jump host must remain private and use a separate subnet from nodes."
  }
}

# OpenTofu 1.11 cannot populate the absent computed kubelet_identity block.
# Isolate the upstream AKS output contract; this test covers LZ network/access wiring.
# The complete AKS module is still checked by tofu validate.
override_module {
  target = module.landing_zone.module.aks
  outputs = {
    cluster_id          = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.ContainerService/managedClusters/mock-aks"
    cluster_name        = "mock-aks"
    resource_group_name = "mock-rg"
    node_resource_group = "mock-node-rg"
    fqdn                = "mock-aks.example.invalid"
    private_fqdn        = "mock-aks.privatelink.example.invalid"
    subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-nodes"
    kubelet_object_id   = "00000000-0000-0000-0000-000000000004"
  }
}
