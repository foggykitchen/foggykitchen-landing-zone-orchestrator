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
- explicit DNS link intent where applicable
- interconnect staging intent where needed in blueprint-tier scenarios

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

- `drg_cross_region`
- `lpg_local_peering`
- `devops_build_only`
- `devops_build_and_deploy_oke`
- `event_driven_data_pipeline`

## 🧩 Pattern Responsibilities

### Azure Hub-and-Spoke

Focus:

- core network boundary
- hub and spokes
- peering
- optional route tables
- NSGs
- NAT
- Bastion
- optional private DNS
- optional private VM workload
- optional internal load balancer

Example variants:

- `basic` for pure network foundation
- `routing` for router-VM-based spoke-to-spoke transit

### Azure Private Endpoint

Focus:

- reuse hub-and-spoke core
- add Storage
- add private endpoints
- add private DNS zone integration
- optionally add a storage-aware consumer VM through `compute_storage_mounts`

The current routed storage example uses:

- router-VM-based transit between spokes
- Storage private endpoints hosted in the data spoke
- an app VM in another spoke that mounts Azure Files through the private endpoint path

This is intentionally modeled as a private endpoint pattern specialization rather than as a generic extension to the shared `hub_spoke` compute contract.

### Azure Firewall Transit

Focus:

- hub-and-spoke transit pattern
- centralized east-west inspection
- centralized north-south egress
- route tables pointing to Azure Firewall private IP

### OCI DRG Cross-Region

Focus:

- cross-region VCN connectivity
- one DRG per region
- RPC-based remote peering
- explicit VCN-side and DRG-side route flow

### OCI LPG Local Peering

Focus:

- same-region VCN peering
- local route flow through LPGs
- private workloads
- private load balancer

### OCI DevOps Build-Only

Focus:

- OCI DevOps project composition
- GitHub connection backed by OCI Vault secret
- mirrored repository synchronization
- OCI managed build pipeline using reusable DevOps modules
- OCIR image artifact delivery

### OCI DevOps Build-And-Deploy-OKE

Focus:

- OCI DevOps build and deploy composition
- mirrored application and Helm repositories
- OKE cluster as the deployment target
- Helm chart delivery through OCIR
- optional cascade trigger from build pipeline into deploy pipeline
- public workload exposure through Kubernetes `Service` type `LoadBalancer`

### OCI Event-Driven Data Pipeline

Focus:

- public API Gateway entry point
- private OCI Functions application
- initiator function publishing into OCI Streaming
- Service Connector Hub invoking the collector function
- Autonomous Database bootstrap and final persistence
- end-to-end asynchronous handoff from HTTP request to stored database record

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
- OCI DRG cross-region and LPG-based networking patterns
- OCI DevOps build-only pattern
- OCI DevOps build-and-deploy-OKE pattern
- OCI event-driven data pipeline pattern

Not yet treated as first-class pattern families:

- OCI file storage patterns
- OCI object storage patterns
- OCI bastion service integration
- OCI block volume patterns
- advanced multicloud premium blueprints in the private `foggykitchen-landing-zone-blueprint` repository
- enterprise governance overlays
- policy-as-code

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
