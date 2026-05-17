# FoggyKitchen Landing Zone Orchestrator

FoggyKitchen Landing Zone Orchestrator is a reference architecture layer built on top of public **Terraform / OpenTofu modules** from the FoggyKitchen ecosystem for **Azure** and **OCI**.

It demonstrates how reusable infrastructure modules can be composed into opinionated landing zone patterns: hub-and-spoke networking, private-first compute, private endpoints, DRG-based transit, local peering, private DNS, and future multicloud expansion.

This repository is a reference implementation and educational architecture pattern.  
It is **not** a drop-in enterprise landing zone product.  
Review security, governance, compliance, identity, networking, and operational requirements before using it in production.

---

## 🎯 Purpose

The goal of this repository is to provide a **clear, educational, and architecture-aware orchestration layer** for landing zone composition:

- YAML-driven **Architecture-as-Payload**
- Static, reviewable Terraform / OpenTofu module composition
- Thin orchestration instead of a giant generic supermodule
- Reusable patterns across Azure and OCI
- A clean reference base for courses, demos, and future examples

This repository is **not** trying to replace Azure CAF or full enterprise landing zone frameworks.  
It is a **learning-first, composition-first reference implementation**.

---

## ✨ What the repository does

Depending on the selected pattern and payload, the repository can compose:

- Azure hub-and-spoke landing zones
- Azure private endpoint landing zones
- Azure firewall transit landing zones
- OCI DRG hub-and-spoke landing zones
- OCI same-region LPG local peering landing zones
- OCI-Azure Interconnect reference landing zones
- Private-first compute placement
- Private DNS integration
- Internal load balancing
- Storage plus private endpoint service exposure

The repository intentionally does **not** aim to provide:

- a giant multi-cloud supermodule
- dynamic module source selection from YAML
- enterprise governance, policy, or RBAC frameworks
- production-readiness guarantees without review

Each architecture remains **explicit, static, and understandable**.

---

## 🧠 Architecture-as-Payload

The core idea is simple:

1. A YAML payload describes architecture intent.
2. Terraform / OpenTofu decodes that payload.
3. Static FoggyKitchen module calls implement the selected pattern.

The payload controls naming, topology, feature flags, CIDR ranges, subnet intent, routing intent, and workload placement. Module sources remain explicit and static in HCL.

---

## 📂 Repository Structure

```bash
foggykitchen-landing-zone-orchestrator/
├── docs/
├── examples/
│   ├── azure/
│   │   ├── README.md
│   │   └── networking/
│   │       ├── README.md
│   │       ├── hub_spoke/
│   │       │   └── basic/
│   │       └── private_endpoint/
│   │           └── storage_private_link/
│   ├── oci/
│   │   ├── README.md
│   │   └── networking/
│   │       ├── README.md
│   │       ├── drg_hub_spoke/
│   │       │   └── basic/
│   │       └── lpg_local_peering/
│   │           └── basic/
│   └── multicloud/
│       ├── README.md
│       └── interconnect/
│           ├── README.md
│           └── oci_azure_interconnect/
│               └── basic/
├── patterns/
│   ├── azure/
│   │   ├── hub_spoke/
│   │   └── private_endpoint/
│   ├── oci/
│       ├── drg_hub_spoke/
│       └── lpg_local_peering/
│   └── multicloud/
│       └── oci_azure_interconnect/
├── scripts/
├── LICENSE
└── README.md
```

---

## 🚀 Implemented Patterns

Currently implemented:

- [examples/azure/networking/hub_spoke/basic](examples/azure/networking/hub_spoke/basic/README.md)
- [examples/azure/networking/firewall_transit/basic](examples/azure/networking/firewall_transit/basic/README.md)
- [examples/azure/networking/private_endpoint/storage_private_link](examples/azure/networking/private_endpoint/storage_private_link/README.md)
- [examples/oci/networking/drg_hub_spoke/basic](examples/oci/networking/drg_hub_spoke/basic/README.md)
- [examples/oci/networking/lpg_local_peering/basic](examples/oci/networking/lpg_local_peering/basic/README.md)
- [examples/multicloud/interconnect/oci_azure_interconnect/basic](examples/multicloud/interconnect/oci_azure_interconnect/basic/README.md)

Shared orchestration patterns:

- [patterns/azure/hub_spoke](patterns/azure/hub_spoke)
- [patterns/azure/firewall_transit](patterns/azure/firewall_transit)
- [patterns/azure/private_endpoint](patterns/azure/private_endpoint)
- [patterns/oci/drg_hub_spoke](patterns/oci/drg_hub_spoke)
- [patterns/oci/lpg_local_peering](patterns/oci/lpg_local_peering)
- [patterns/multicloud/oci_azure_interconnect](patterns/multicloud/oci_azure_interconnect)

The `OCI-Azure Interconnect` pattern is intentionally transitional at this stage:

- Azure and OCI landing zone foundations use FoggyKitchen modules where they fit well
- ExpressRoute, FastConnect, and related edge interconnect resources are still implemented as raw provider resources in the orchestrator
- this will be improved over time as dedicated FoggyKitchen modules for interconnect edge components are introduced

---

## 🧩 Module Composition

The repository composes FoggyKitchen building blocks such as:

- `terraform-az-fk-vnet`
- `terraform-az-fk-vnet-peering`
- `terraform-az-fk-routing`
- `terraform-az-fk-nsg`
- `terraform-az-fk-public-ip`
- `terraform-az-fk-natgw`
- `terraform-az-fk-bastion`
- `terraform-az-fk-private-dns`
- `terraform-az-fk-compute`
- `terraform-az-fk-storage`
- `terraform-az-fk-private-endpoint`
- `terraform-oci-fk-vcn`
- `terraform-oci-fk-lpg`
- `terraform-oci-fk-drg`
- `terraform-oci-fk-compute`
- `terraform-oci-fk-loadbalancer`

The current Azure internal load balancer examples still use direct AzureRM resources because the current `terraform-az-fk-loadbalancer` module is public-frontend oriented.

The current `OCI-Azure Interconnect` example also mixes FoggyKitchen modules with raw provider resources for the interconnect edge layer. This is deliberate for now and will be refactored as the module catalog expands.

---

## 📘 Getting Started

Start with:

- [docs/architecture.md](docs/architecture.md)
- [docs/payload-contract.md](docs/payload-contract.md)
- [docs/module-map.md](docs/module-map.md)

Then choose one of the example payloads under `examples/`.

---

## 🛣️ Roadmap

- Add more payload variants under `examples/azure`, `examples/oci`, and `examples/multicloud`
- Harden module source pinning to explicit tags
- Extend Azure private endpoint coverage beyond Storage
- Expand OCI examples with more service integrations

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
