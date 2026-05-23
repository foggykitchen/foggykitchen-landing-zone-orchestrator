# Azure Firewall Transit Pattern

This directory contains the shared **Azure firewall transit landing zone pattern** used by FoggyKitchen Landing Zone Orchestrator.

---

## 🎯 Purpose

The goal of this pattern is to provide a reusable Azure topology for:

- centralized east-west inspection
- centralized north-south egress
- spoke routing through Azure Firewall
- private workload placement in spokes

---

## ✨ What The Pattern Builds

The pattern composes:

- one Azure Resource Group
- one hub VNet
- multiple spoke VNets
- hub-and-spoke peering
- Azure Firewall with public IP
- route tables that point spokes to the firewall private IP
- private VM workloads in spokes

---

## 📂 Key Files

- [`main.tf`](main.tf)
- [`locals.tf`](locals.tf)
- [`variables.tf`](variables.tf)
- [`outputs.tf`](outputs.tf)
- [`versions.tf`](versions.tf)

This pattern is consumed by:

- [`examples/azure/networking/firewall_transit/basic`](../../../../examples/azure/networking/firewall_transit/basic/README.md)

---

## 🧩 Input Model

The pattern expects:

- `payload_file`

The payload is expected to describe sections such as:

- `landing_zone`
- `cloud`
- `networking`
- `peering`
- `firewall`
- `routing`
- `compute`

Firewall rule collections and compute placement are normalized in [`locals.tf`](locals.tf).

---

## 📤 Outputs

The pattern exposes outputs for:

- resource group name
- hub and spoke VNet IDs
- firewall ID
- firewall private and public IPs
- route table IDs
- VM private IPs
- peering IDs

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
