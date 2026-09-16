# Azure AKS Basic Example

This example composes a **private Azure Kubernetes Service cluster** with a minimal self-contained VNet, Azure Bastion operator access, NAT Gateway egress, and a small private jump host.

It is the public teaser-tier counterpart to the premium `aks_firewall_transit` blueprint. Move to that blueprint when the architecture requires Azure Firewall transit, ACR, customer-managed keys, additional node pools, or broader governance.

## Architecture Overview

<img src="diagrams/azure_aks_basic_architecture.jpg" alt="Azure AKS basic private cluster architecture" width="900"/>

**Figure 1.** Azure AKS basic private cluster architecture.

The `aks_basic` pattern composes one VNet with an AKS node subnet, a dedicated jump subnet, and `AzureBastionSubnet`; separate subnet-associated NSGs for AKS nodes and the jump host; one empty route table associated to the AKS node subnet for AKS `userDefinedRouting`; one NAT Gateway associated to the AKS node and jump subnets; one private AKS cluster; one Azure Bastion host; and one private Linux jump host used to validate private AKS API reachability.

## What This Example Deploys

- one Resource Group
- one VNet
- one AKS node subnet
- one private jump subnet
- one `AzureBastionSubnet`
- one NSG associated to the AKS node subnet
- one NSG associated to the jump subnet
- one empty route table associated to the AKS node subnet
- one NAT Gateway with a public IP for outbound egress from the AKS node and jump subnets
- one private AKS cluster using Azure CNI
- one Azure Bastion host for SSH access to the private jump host
- one lightweight Linux jump host used to validate private AKS API TCP `443` reachability

## Pattern

- [`patterns/azure/aks_basic`](../../../../patterns/azure/aks_basic/README.md)

## Files

- [landing-zone.yaml](landing-zone.yaml)
- [main.tf](main.tf)
- [providers.tf](providers.tf)
- [variables.tf](variables.tf)
- [outputs.tf](outputs.tf)
- [terraform.tfvars.example](terraform.tfvars.example)

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu validate
```

Replace the placeholder values in `terraform.tfvars` before running a real plan or apply.

This PR validates only `tofu fmt`, `tofu init`, and `tofu validate`. It does not run `tofu plan` or `tofu apply` against a real subscription.

## Validation Flow

After a manual apply, use the `jump_host.ssh_command` output to connect to the private jump host through Azure Bastion, then validate AKS private API reachability:

```bash
az network bastion ssh --name <bastion-name> --resource-group <resource-group-name> --target-resource-id <jump-vm-id> --auth-type ssh-key --username azureuser --ssh-key <path-to-private-key>
getent hosts <aks-private-fqdn>
nc -vz <aks-private-fqdn> 443
```

Expected result:

- AKS exposes a private FQDN
- TCP port `443` is reachable from the private jump host
- the jump host has no public IP and operator SSH goes through Azure Bastion
- direct Internet-originated inbound traffic to the AKS node subnet is denied by NSG
- AKS uses `outbound_type = "userDefinedRouting"` with an empty route table, while the subnet-associated NAT Gateway provides outbound egress for private nodes

## Destroy

```bash
tofu destroy
```

## Notes

- `admin_ssh_public_key` is a sensitive Terraform variable and is injected into `landing-zone.yaml` with `templatefile`.
- This basic variant does not configure Azure Firewall, hub-and-spoke topology, ACR, customer-managed keys, additional node pools, autoscaling, diagnostics, Log Analytics, multi-region, cross-region, or disaster recovery configuration.
- `terraform-az-fk-aks v2.0.0` exposes `kubeconfig_raw`, but this orchestrator pattern deliberately does not output raw kubeconfig or secrets.
- This implementation follows the FoggyKitchen `terraform-az-fk-aks` `training/03-private-cluster` lab: `userDefinedRouting` is intentional, the AKS node subnet has an associated empty route table, and NAT Gateway provides the outbound internet path for private nodes.

## Learn More

- [FoggyKitchen Azure AKS Terraform Course](https://foggykitchen.com/courses/azure-aks-terraform-course)
- [Create a private Azure Kubernetes Service cluster](https://learn.microsoft.com/en-us/azure/aks/private-clusters)
- [Customize AKS cluster egress with outbound types](https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype)
- [Create a managed or user-assigned NAT Gateway for AKS](https://learn.microsoft.com/en-us/azure/aks/nat-gateway)
- [Design virtual networks with Azure NAT Gateway](https://learn.microsoft.com/en-us/azure/nat-gateway/nat-gateway-design)
- [Create an SSH connection to a Linux VM using Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/bastion-connect-vm-ssh-linux)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
