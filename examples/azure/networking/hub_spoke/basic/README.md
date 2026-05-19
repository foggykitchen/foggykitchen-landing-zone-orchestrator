# Azure Hub-and-Spoke Landing Zone

This example provides one payload for the shared **Azure hub-and-spoke orchestrator pattern**.

![Azure hub-and-spoke architecture](diagrams/azure-hub-spoke-basic-architecture.png)

---

## 🎯 Purpose

The goal of this example is to show a **clean, reusable Azure landing zone composition** built from FoggyKitchen modules:

- hub-and-spoke networking
- subnet-level security boundaries
- NAT-based outbound access
- Bastion-based operator access
- foundational landing zone scaffolding

---

## ✨ What the example does

This example composes:

- one resource group
- one hub VNet
- one app spoke VNet
- one data spoke VNet
- hub-to-spoke peering
- subnet-level NSGs
- NAT Gateway on selected private subnets
- Azure Bastion in the hub
- reserved application and data subnets for future workload patterns

---

## 🖼️ Azure Portal View

The screenshot below shows the deployed `basic` scaffold in Azure Portal after a successful `apply`.
It gives a quick visual confirmation that the hub VNet, both spoke VNets, Bastion, NAT Gateways, and their Public IPs were created as expected.

![Azure Portal view of the deployed basic hub-and-spoke landing zone](diagrams/azure-hub-spoke-basic-portal1.png)

One portal screenshot is enough here as long as it clearly shows:

- the resource group scope
- the hub and two spoke VNets
- Bastion
- both NAT Gateways and their Public IPs

---

## 📂 Pattern And Payload

The shared pattern lives in:

- [`patterns/azure/hub_spoke`](../../../../../patterns/azure/hub_spoke)

This example contributes:

- [`landing-zone.yaml`](landing-zone.yaml)
- a thin wrapper [`main.tf`](main.tf)
- provider configuration

The wrapper passes the payload into the shared HCL pattern, so the pattern code stays common and the payload carries the architecture intent.

This basic example is intentionally **foundation-only**.
It prepares the network, security, peering, egress, and operator-access layers without deploying application workloads, private endpoints, or cross-spoke transit.

---

## 🧩 Module Map

- `terraform-az-fk-vnet` for hub and spoke VNets
- `terraform-az-fk-vnet-peering` for connectivity
- `terraform-az-fk-nsg` for subnet-level security boundaries
- `terraform-az-fk-public-ip` for NAT public identity
- `terraform-az-fk-natgw` for outbound egress
- `terraform-az-fk-bastion` for secure operator access

---

## 🚀 Deployment

OpenTofu:

```bash
tofu init
tofu plan
tofu apply
```

Terraform:

```bash
terraform init
terraform plan
terraform apply
```

---

## 📤 Expected Outputs

- resource group name
- hub and spoke VNet IDs
- subnet IDs
- NAT Gateway public IP
- Bastion name

---

## 🧹 Cleanup

OpenTofu:

```bash
tofu destroy
```

Terraform:

```bash
terraform destroy
```

---

## ⚠️ Known Limitations

- No application, database, or shared-services VMs are deployed in this basic scaffold.
- Private DNS and private endpoints are addressed separately by the `private_endpoint` pattern.
- Hub-based transit routing is addressed separately by the `hub_spoke/routing` and `firewall_transit` patterns.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
