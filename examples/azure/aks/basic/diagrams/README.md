# Diagrams

This directory is reserved for screenshots captured after a manual `tofu apply`.

Suggested evidence for this example:

- AKS basic architecture diagram
- Resource Group overview
- VNet subnets showing AKS node subnet, jump subnet, and `AzureBastionSubnet`
- AKS cluster overview
- AKS networking page showing private cluster configuration
- NAT Gateway overview and subnet association
- Azure Bastion overview
- jump VM networking page showing private IP only in the jump subnet
- node and jump NSG rules for denied Internet inbound and Bastion-sourced SSH/RDP to the jump subnet
- Bastion session output showing private AKS API DNS and TCP `443` validation

Do not commit Terraform state, provider caches, SSH private keys, or generated kubeconfig files here.
