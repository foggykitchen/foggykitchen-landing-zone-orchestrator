# Diagrams

This directory contains screenshots captured after a manual `tofu apply`.

Evidence captured for this example:

- `azure_aks_basic_architecture.jpg` - AKS basic architecture diagram
- `azure_aks_basic_resource_group_overview.jpg` - Resource Group overview
- `azure_aks_basic_vnet_subnets.jpg` - VNet subnets showing AKS node subnet, jump subnet, and `AzureBastionSubnet`
- `azure_aks_basic_aks_overview.jpg` - AKS cluster overview
- `azure_aks_basic_aks_networking.jpg` - AKS networking page showing private cluster configuration
- `azure_aks_basic_route_table.jpg` - empty route table associated to the AKS node subnet
- `azure_aks_basic_nat_gateway.jpg` - NAT Gateway overview and subnet association
- `azure_aks_basic_bastion_overview.jpg` - Azure Bastion overview
- `azure_aks_basic_jump_vm_networking.jpg` - jump VM networking page showing private placement in the jump subnet
- `azure_aks_basic_node_nsg_rules.jpg` - AKS node subnet NSG rules denying direct Internet inbound traffic
- `azure_aks_basic_jump_nsg_rules.jpg` - jump subnet NSG rules allowing SSH only from the Bastion subnet and denying direct Internet inbound traffic

The Bastion validation output is recorded in the parent example README instead of as a screenshot.

Do not commit Terraform state, provider caches, SSH private keys, or generated kubeconfig files here.
