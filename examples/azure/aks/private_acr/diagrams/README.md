# Diagrams

This directory is reserved for screenshots captured after a manual `tofu apply`.

Suggested evidence for this example:

- `azure_aks_private_acr_architecture.jpg` - AKS private ACR architecture diagram
- `azure_aks_private_acr_resource_group_overview.jpg` - Resource Group overview
- `azure_aks_private_acr_vnet_subnets.jpg` - VNet subnets showing AKS node, jump, ACR Private Endpoint, and `AzureBastionSubnet`
- `azure_aks_private_acr_aks_overview.jpg` - AKS cluster overview
- `azure_aks_private_acr_aks_networking.jpg` - AKS networking page showing private cluster configuration
- `azure_aks_private_acr_acr_overview.jpg` - ACR overview with Premium SKU
- `azure_aks_private_acr_acr_networking.jpg` - ACR networking with public access disabled and Private Endpoint access enabled
- `azure_aks_private_acr_private_endpoint.jpg` - ACR Private Endpoint overview
- `azure_aks_private_acr_private_endpoint_dns.jpg` - ACR Private Endpoint DNS configuration
- `azure_aks_private_acr_private_dns_zone.jpg` - Private DNS Zone records for `privatelink.azurecr.io`
- `azure_aks_private_acr_route_table.jpg` - empty route table associated to the AKS node subnet
- `azure_aks_private_acr_nat_gateway.jpg` - NAT Gateway overview and subnet association
- `azure_aks_private_acr_bastion_overview.jpg` - Azure Bastion overview
- `azure_aks_private_acr_jump_vm_networking.jpg` - jump VM networking page showing private placement in the jump subnet
- `azure_aks_private_acr_node_nsg_rules.jpg` - AKS node subnet NSG rules denying direct Internet inbound traffic
- `azure_aks_private_acr_jump_nsg_rules.jpg` - jump subnet NSG rules allowing SSH only from the Bastion subnet and denying direct Internet inbound traffic

Record Bastion validation output in the parent example README after deployment instead of committing secrets or generated kubeconfig files here.

Do not commit Terraform state, provider caches, SSH private keys, generated kubeconfig files, or pushed container images here.
