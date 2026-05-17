# Architecture

This document explains the **high-level architecture model** used by FoggyKitchen Landing Zone Orchestrator.

---

## 🎯 Purpose

The goal of this repository is not to create one giant landing zone supermodule.  
Instead, it provides a **thin orchestration layer** that composes reusable FoggyKitchen modules into architecture-driven patterns.

The core idea is:

- YAML payloads describe architecture intent
- shared HCL patterns implement that intent
- examples provide payload variants and thin wrappers

---

## 🧠 Core Model

The orchestrator treats YAML as an **architecture contract** rather than a raw resource manifest.

The payload expresses:

- topology
- access model
- routing intent
- security intent
- feature switches
- workload placement
- interconnect staging intent where needed

Terraform / OpenTofu then maps that intent to **statically declared** FoggyKitchen module calls and, in a few cases, explicit provider resources where the module catalog is not yet complete.

---

## 📂 Repository Architecture

The repository is organized around two layers:

1. `patterns/`
   - shared HCL orchestration logic
   - one directory per reusable architecture pattern
2. `examples/`
   - payload-driven example variants
   - thin wrappers that call shared patterns

This separation keeps the implementation:

- understandable
- testable
- scalable as more examples are added

---

## ✨ Currently Implemented Pattern Families

### Azure

- `hub_spoke`
- `private_endpoint`
- `firewall_transit`

### OCI

- `drg_hub_spoke`
- `lpg_local_peering`

### Multicloud

- `oci_azure_interconnect`

---

## 🧩 Pattern Responsibilities

### Azure Hub-and-Spoke

Focus:

- core network boundary
- hub and spokes
- peering
- route tables
- NSGs
- NAT
- Bastion
- private DNS
- private VM workload
- internal load balancer

### Azure Private Endpoint

Focus:

- reuse hub-and-spoke core
- add Storage
- add private endpoints
- add private DNS zone integration

### Azure Firewall Transit

Focus:

- hub-and-spoke transit pattern
- centralized east-west inspection
- centralized north-south egress
- route tables pointing to Azure Firewall private IP

### OCI DRG Hub-and-Spoke

Focus:

- multi-VCN connectivity
- DRG attachments
- DRG route flow
- private workloads
- private load balancer

### OCI LPG Local Peering

Focus:

- same-region VCN peering
- local route flow through LPGs
- private workloads
- private load balancer

### OCI-Azure Interconnect

Focus:

- Azure ExpressRoute side
- OCI FastConnect side
- DRG-based OCI attachment
- private workload connectivity across clouds

This pattern is intentionally transitional at the moment and still mixes:

- FoggyKitchen modules for foundational layers
- raw provider resources for interconnect edge components

---

## ⚖️ Why Thin Composition

This repository intentionally does not reimplement all networking, compute, DNS, firewall, or storage internals.

Those concerns stay inside dedicated modules where possible.  
The orchestrator is responsible for:

- payload normalization
- reference resolution
- static module wiring
- architecture-level composition

---

## ⚠️ Current Architectural Boundaries

Included today:

- Azure landing zone networking patterns
- Azure private endpoint pattern for Storage
- Azure firewall transit pattern
- OCI DRG and LPG-based networking patterns
- OCI-Azure interconnect reference pattern

Not yet treated as first-class pattern families:

- OCI file storage patterns
- OCI object storage patterns
- OCI bastion service integration
- OCI block volume patterns
- enterprise governance overlays
- CI/CD and policy-as-code

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
