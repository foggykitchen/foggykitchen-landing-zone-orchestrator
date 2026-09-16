# Azure AKS Basic Pattern

This pattern composes a private Azure Kubernetes Service cluster, a small self-contained VNet, Azure Bastion, NAT Gateway egress, subnet-level NSG rules, and a lightweight private jump host into a public teaser-tier AKS landing-zone pattern.

It is the public counterpart to the premium `aks_firewall_transit` blueprint. Upgrade to that blueprint when the architecture requires Firewall-based transit, ACR integration, customer-managed keys, multiple node pools, or broader platform governance.

## Summary

This pattern is intentionally scoped to a **single-region private AKS baseline**:

- one VNet with one AKS node subnet, one jump subnet, and `AzureBastionSubnet`
- one NSG associated to the AKS node subnet
- one NSG associated to the jump subnet
- one empty route table associated to the AKS node subnet for AKS `userDefinedRouting`
- one NAT Gateway associated to the AKS node and jump subnets for outbound egress
- one private AKS cluster using Azure CNI and `outbound_type = "userDefinedRouting"`
- one Azure Bastion host used for operator SSH access to the private jump host
- one lightweight Linux jump host used to validate private AKS API TCP `443` reachability

It deliberately excludes:

- Azure Firewall
- hub-and-spoke multi-VNet topology
- spoke-to-spoke transit
- Azure Container Registry, private or public
- customer-managed key encryption
- additional or user node pools
- node-pool autoscaling
- diagnostic settings or Log Analytics integration
- multi-region, cross-region, or disaster recovery configuration

Those concerns belong in the premium `aks_firewall_transit` blueprint rather than this public teaser-tier pattern.

## Payload Scope

The pattern consumes:

- `architecture.network.vnet`
- `architecture.network.node_subnet`
- `architecture.network.jump_subnet`
- `architecture.network.bastion_subnet`
- optional `architecture.network.nat_gateway`
- optional `architecture.network.route_table`
- `workload.jump`
- `data.aks.cluster`
- `data.aks.default_node_pool`

Optional `data.aks.acr`, `data.aks.cmk`, `data.aks.diagnostics`, and `data.aks.additional_node_pools` blocks are decoded defensively but rejected by this pattern until a richer blueprint-tier implementation wires them explicitly.

## Examples

- [`examples/azure/aks/basic`](../../../examples/azure/aks/basic/README.md)

## Learn More

- [FoggyKitchen Azure AKS Terraform Course](https://foggykitchen.com/courses/azure-aks-terraform-course)
- [Create a private Azure Kubernetes Service cluster](https://learn.microsoft.com/en-us/azure/aks/private-clusters)
- [Customize AKS cluster egress with outbound types](https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype)
- [Create a managed or user-assigned NAT Gateway for AKS](https://learn.microsoft.com/en-us/azure/aks/nat-gateway)
- [Design virtual networks with Azure NAT Gateway](https://learn.microsoft.com/en-us/azure/nat-gateway/nat-gateway-design)
- [Create an SSH connection to a Linux VM using Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/bastion-connect-vm-ssh-linux)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
