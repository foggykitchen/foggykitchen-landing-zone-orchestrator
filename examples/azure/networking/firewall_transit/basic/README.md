# Azure Firewall Transit Landing Zone

This example provides one payload for the shared **Azure firewall transit orchestrator pattern**.

![Azure firewall transit architecture](diagrams/firewall_transit_basic_architecture.png)

---

## 🎯 Purpose

The goal of this example is to show a **hub-spoke transit and centralized egress pattern** built around Azure Firewall:

- east-west inspection between spokes
- centralized north-south egress
- UDR-based transit through the hub
- managed firewall instead of a router VM or NVA

---

## ✨ What the example does

This example composes:

- one resource group
- one hub VNet
- two spoke VNets
- one `AzureFirewallSubnet` in the hub
- hub-to-spoke peering
- one Azure Firewall with a standard public IP
- one route table per spoke with next hop set to the firewall private IP
- one private Linux VM in each spoke for validation traffic

---

## 📂 Pattern And Payload

The shared pattern lives in:

- [`patterns/azure/firewall_transit`](../../../../../patterns/azure/firewall_transit)

This example contributes:

- [`landing-zone.yaml`](landing-zone.yaml)
- a thin wrapper [`main.tf`](main.tf)
- provider configuration

The payload describes the transit-firewall intent, while the shared HCL pattern resolves the firewall, routes, peering, and validation workloads.

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

If you want to inject your own public key instead of generating one automatically, pass:

```bash
tofu apply -var="admin_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

---

## 📤 Expected Outputs

- resource group name
- hub and spoke VNet IDs
- firewall ID
- firewall private IP
- firewall public IP
- route table IDs
- spoke VM private IPs
- generated admin SSH private key PEM when `admin_ssh_public_key` is left empty

---

## 🧹 Cleanup

```bash
tofu destroy
```

---

## ⚠️ Known Limitations

- This example focuses on minimal transit-firewall behavior, not a full enterprise firewall policy.
- Firewall rule collections are intentionally simple and payload-driven.
- It complements the basic hub-spoke and private endpoint examples rather than replacing them.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
