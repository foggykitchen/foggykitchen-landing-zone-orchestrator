# FoggyKitchen Landing Zone Orchestrator

FoggyKitchen Landing Zone Orchestrator is a reference architecture layer built on top of public **Terraform / OpenTofu modules** from the FoggyKitchen ecosystem for **Azure** and **OCI**.

It demonstrates how reusable infrastructure modules can be composed into opinionated landing zone patterns: hub-and-spoke networking, private-first compute, private endpoints, DRG cross-region remote peering, local peering, private DNS, firewall-based transit, and OCI multiregion failover.
It also starts to show how the same orchestration model can be extended into OCI ADB private access, OCI DevOps delivery patterns, and OCI Functions patterns built from reusable FoggyKitchen modules.

This repository is a reference implementation and educational architecture pattern.  
It is **not** a drop-in enterprise landing zone product.  
Review security, governance, compliance, identity, networking, and operational requirements before using it in production.

Support expectations are documented in [SUPPORT.md](SUPPORT.md).

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
- OCI DRG cross-region landing zones
- OCI same-region LPG local peering landing zones
- OCI multiregion compute failover patterns
- OCI private Autonomous Database patterns
- OCI DevOps build and deploy patterns
- OCI OKE deployment target patterns
- OCI authenticated serverless API patterns
- OCI Functions-based event-driven data patterns
- OCI bulk ingestion pipelines
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

Minimal example:

```yaml
landing_zone:
  name: fk-azure-lz-dev
  environment: dev

cloud:
  provider: azure
  location: westeurope

architecture:
  topology: hub_spoke
  access_model: private_first
  routing_model: none
  security_model: deny_by_default

features:
  vnet_peering: true
  nsg: true
  compute: false

networking:
  hub:
    name: vnet-fk-hub-dev
    address_space:
      - 10.10.0.0/16
    subnets:
      shared:
        name: snet-fk-shared-services
        cidr: 10.10.1.0/24
  spokes:
    app:
      name: vnet-fk-app-dev
      address_space:
        - 10.20.0.0/16
      subnets:
        backend:
          name: snet-fk-app-backend
          cidr: 10.20.2.0/24
```

See the runnable payloads under [examples/](examples/) for complete provider, variable, and validation context.

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
│   │       ├── firewall_transit/
│   │       │   └── basic/
│   │       ├── hub_spoke/
│   │       │   ├── README.md
│   │       │   ├── basic/
│   │       │   └── routing/
│   │       └── private_endpoint/
│   │           └── storage_private_link/
│   ├── oci/
│   │   ├── README.md
│   │   ├── adb/
│   │   │   └── private_access/
│   │   │       └── basic/
│   │   ├── devops/
│   │   │   ├── build_and_deploy_oke/
│   │   │   │   └── basic/
│   │   │   └── build_only/
│   │   │       └── basic/
│   │   ├── functions/
│   │   │   ├── authenticated_serverless_api/
│   │   │   │   └── basic/
│   │   │   ├── bulk_ingestion_pipeline/
│   │   │   │   └── basic/
│   │   │   └── event_driven_data_pipeline/
│   │   │       └── basic/
│   │   ├── multiregion/
│   │   │   └── compute_failover/
│   │   │       └── basic/
│   │   └── networking/
│   │       ├── README.md
│   │       ├── drg_cross_region/
│   │       │   └── basic/
│   │       └── lpg_local_peering/
│   │           └── basic/
│   └── multicloud/
│       ├── README.md
│       └── interconnect/
│           └── README.md
├── patterns/
│   ├── azure/
│   │   ├── firewall_transit/
│   │   ├── hub_spoke/
│   │   └── private_endpoint/
│   ├── oci/
│       ├── adb_private_access/
│       ├── authenticated_serverless_api/
│       ├── devops_build_and_deploy_oke/
│       ├── devops_build_only/
│       ├── bulk_ingestion_pipeline/
│       ├── event_driven_data_pipeline/
│       ├── drg_cross_region/
│       ├── lpg_local_peering/
│       └── multiregion_compute_failover/
│   └── multicloud/
│       └── README.md
├── scripts/
├── LICENSE
└── README.md
```

---

## 🚀 Implemented Patterns

Currently implemented:

- [examples/azure/networking/hub_spoke/basic](examples/azure/networking/hub_spoke/basic/README.md)
- [examples/azure/networking/hub_spoke/routing](examples/azure/networking/hub_spoke/routing/README.md)
- [examples/azure/networking/firewall_transit/basic](examples/azure/networking/firewall_transit/basic/README.md)
- [examples/azure/networking/private_endpoint/storage_private_link](examples/azure/networking/private_endpoint/storage_private_link/README.md)
- [examples/oci/networking/drg_cross_region/basic](examples/oci/networking/drg_cross_region/basic/README.md)
- [examples/oci/networking/lpg_local_peering/basic](examples/oci/networking/lpg_local_peering/basic/README.md)
- [examples/oci/multiregion/compute_failover/basic](examples/oci/multiregion/compute_failover/basic/README.md)
- [examples/oci/adb/private_access/basic](examples/oci/adb/private_access/basic/README.md)
- [examples/oci/devops/build_only/basic](examples/oci/devops/build_only/basic/README.md)
- [examples/oci/devops/build_and_deploy_oke/basic](examples/oci/devops/build_and_deploy_oke/basic/README.md)
- [examples/oci/functions/authenticated_serverless_api/basic](examples/oci/functions/authenticated_serverless_api/basic/README.md)
- [examples/oci/functions/bulk_ingestion_pipeline/basic](examples/oci/functions/bulk_ingestion_pipeline/basic/README.md)
- [examples/oci/functions/event_driven_data_pipeline/basic](examples/oci/functions/event_driven_data_pipeline/basic/README.md)

Shared orchestration patterns:

- [patterns/README.md](patterns/README.md)
- [patterns/azure/hub_spoke](patterns/azure/hub_spoke)
- [patterns/azure/firewall_transit](patterns/azure/firewall_transit)
- [patterns/azure/private_endpoint](patterns/azure/private_endpoint)
- [patterns/oci/drg_cross_region](patterns/oci/drg_cross_region)
- [patterns/oci/lpg_local_peering](patterns/oci/lpg_local_peering)
- [patterns/oci/multiregion_compute_failover](patterns/oci/multiregion_compute_failover)
- [patterns/oci/adb_private_access](patterns/oci/adb_private_access)
- [patterns/oci/devops_build_only](patterns/oci/devops_build_only)
- [patterns/oci/devops_build_and_deploy_oke](patterns/oci/devops_build_and_deploy_oke)
- [patterns/oci/authenticated_serverless_api](patterns/oci/authenticated_serverless_api)
- [patterns/oci/bulk_ingestion_pipeline](patterns/oci/bulk_ingestion_pipeline)
- [patterns/oci/event_driven_data_pipeline](patterns/oci/event_driven_data_pipeline)

---

## 🔒 Advanced Blueprints

The public orchestrator repository is intentionally focused on **single-cloud reference patterns**.

Advanced multicloud implementations, including OCI-Azure interconnect scenarios, are being moved to the private:

- `foggykitchen-landing-zone-blueprint`

repository.

That code is **not part of the free public distribution** of this repository. The goal is to keep the open repo clean and educational while reserving the most advanced cross-cloud scenarios for future monetization.

---

## 🧩 Module Composition

The repository composes FoggyKitchen building blocks such as:

- [terraform-az-fk-vnet](https://github.com/foggykitchen/terraform-az-fk-vnet)
- [terraform-az-fk-vnet-peering](https://github.com/foggykitchen/terraform-az-fk-vnet-peering)
- [terraform-az-fk-routing](https://github.com/foggykitchen/terraform-az-fk-routing)
- [terraform-az-fk-nsg](https://github.com/foggykitchen/terraform-az-fk-nsg)
- [terraform-az-fk-public-ip](https://github.com/foggykitchen/terraform-az-fk-public-ip)
- [terraform-az-fk-natgw](https://github.com/foggykitchen/terraform-az-fk-natgw)
- [terraform-az-fk-bastion](https://github.com/foggykitchen/terraform-az-fk-bastion)
- [terraform-az-fk-private-dns](https://github.com/foggykitchen/terraform-az-fk-private-dns)
- [terraform-az-fk-compute](https://github.com/foggykitchen/terraform-az-fk-compute)
- [terraform-az-fk-loadbalancer](https://github.com/foggykitchen/terraform-az-fk-loadbalancer)
- [terraform-az-fk-storage](https://github.com/foggykitchen/terraform-az-fk-storage)
- [terraform-az-fk-private-endpoint](https://github.com/foggykitchen/terraform-az-fk-private-endpoint)
- [terraform-az-fk-firewall](https://github.com/foggykitchen/terraform-az-fk-firewall)
- [terraform-oci-fk-vcn](https://github.com/foggykitchen/terraform-oci-fk-vcn)
- [terraform-oci-fk-nsg](https://github.com/foggykitchen/terraform-oci-fk-nsg)
- [terraform-oci-fk-lpg](https://github.com/foggykitchen/terraform-oci-fk-lpg)
- [terraform-oci-fk-drg](https://github.com/foggykitchen/terraform-oci-fk-drg)
- [terraform-oci-fk-compute](https://github.com/foggykitchen/terraform-oci-fk-compute)
- [terraform-oci-fk-loadbalancer](https://github.com/foggykitchen/terraform-oci-fk-loadbalancer)
- [terraform-oci-fk-dns-steering](https://github.com/foggykitchen/terraform-oci-fk-dns-steering)
- [terraform-oci-fk-ocir](https://github.com/foggykitchen/terraform-oci-fk-ocir)
- [terraform-oci-fk-oke](https://github.com/foggykitchen/terraform-oci-fk-oke)
- [terraform-oci-fk-policy](https://github.com/foggykitchen/terraform-oci-fk-policy)
- [terraform-oci-fk-devops](https://github.com/foggykitchen/terraform-oci-fk-devops)
- [terraform-oci-fk-devops-pipeline](https://github.com/foggykitchen/terraform-oci-fk-devops-pipeline)
- [terraform-oci-fk-api-gateway](https://github.com/foggykitchen/terraform-oci-fk-api-gateway)
- [terraform-oci-fk-function](https://github.com/foggykitchen/terraform-oci-fk-function)
- [terraform-oci-fk-objectstorage](https://github.com/foggykitchen/terraform-oci-fk-objectstorage)
- [terraform-oci-fk-event](https://github.com/foggykitchen/terraform-oci-fk-event)
- [terraform-oci-fk-streaming](https://github.com/foggykitchen/terraform-oci-fk-streaming)
- [terraform-oci-fk-sch](https://github.com/foggykitchen/terraform-oci-fk-sch)
- [terraform-oci-fk-adb](https://github.com/foggykitchen/terraform-oci-fk-adb)

---

## 📘 Getting Started

Start with:

- [docs/README.md](docs/README.md)
- [docs/architecture.md](docs/architecture.md)
- [docs/payload-contract.md](docs/payload-contract.md)
- [docs/module-map.md](docs/module-map.md)

Then choose one of the example payloads under `examples/`.

---

## 🛣️ Roadmap

- Add more payload variants under `examples/azure` and `examples/oci`
- Harden module source pinning to explicit tags
- Extend Azure private endpoint coverage beyond Storage
- Expand OCI examples with more service integrations
- Expand OCI DevOps patterns beyond build-only into deploy, trigger, canary, and blue-green flows

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
