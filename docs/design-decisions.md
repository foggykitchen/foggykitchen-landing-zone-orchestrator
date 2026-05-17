# Design Decisions

This document summarizes the key **engineering decisions and tradeoffs** made in the repository.

---

## 🎯 Purpose

The goal of these decisions is to keep the orchestrator:

- explicit
- composable
- architecture-first
- easy to review and extend

---

## 🧠 Static Module Sources

All FoggyKitchen modules are declared **statically in HCL**.

Why:

- keeps the implementation reviewable
- matches Terraform / OpenTofu module resolution rules
- avoids dangerous or opaque dynamic source loading

This means the YAML payload can control intent, but **not** module source locations.

---

## 🧩 Shared Patterns + Thin Examples

The repository uses:

- `patterns/` for shared orchestration logic
- `examples/` for payload variants and wrapper entry points

Why:

- avoids copying the same HCL into every example
- makes payload comparison easy
- scales better than flat numbered examples

---

## 📂 Domain-Oriented Example Layout

Examples are grouped by:

- cloud
- domain
- pattern
- variant

Why:

- avoids a flat `01`, `02`, `03`, ... sprawl
- remains searchable as the catalog grows
- mirrors the mental model already present in `patterns/`

---

## 🏗️ Direct Resource Group in Azure Patterns

Azure patterns create the Resource Group directly with `azurerm_resource_group`.

Why:

- the brief explicitly allowed it
- there is no dedicated FoggyKitchen Resource Group module in scope
- adding indirection here would not improve the architecture

---

## 🌐 Direct Internal Load Balancer in Azure

The current `terraform-az-fk-loadbalancer` module is public-frontend focused.  
The Azure examples requiring an internal load balancer therefore use direct AzureRM resources.

Why:

- the architecture needs ILB behavior now
- the module catalog does not yet cover that exact case cleanly

This is a temporary, explicit tradeoff.

---

## 🔥 Dedicated Firewall Transit Pattern

Azure Firewall was not folded into the baseline `hub_spoke` pattern.

Instead, it was separated into:

- `patterns/azure/firewall_transit`

Why:

- it represents a distinct topology and operational model
- it changes routing intent materially
- it deserves its own payload contract and example lineage

---

## 🔁 Routing As Architecture

Routing is treated as a first-class concern in the patterns.

Why:

- without routing, many examples would only be network skeletons
- DRG, LPG, firewall transit, and interconnect patterns are primarily about route intent

This is why routing is visible in payload structure and not hidden behind too much abstraction.

---

## 🌉 OCI-Azure Interconnect Uses Raw Edge Resources

The `oci_azure_interconnect` pattern currently mixes:

- FoggyKitchen modules for Azure and OCI foundations
- raw provider resources for:
  - ExpressRoute Circuit
  - Azure Virtual Network Gateway
  - FastConnect Virtual Circuit
  - related DRG edge resources

Why:

- there are no dedicated FoggyKitchen modules yet for ExpressRoute and FastConnect edge components
- forcing these edge resources into unrelated modules would blur responsibilities

This is a known transitional state and is expected to improve later.

---

## ⏳ Staged Azure Connection for Interconnect

`azurerm_virtual_network_gateway_connection` is controlled by:

- `interconnect.azure.connection.enabled`

Why:

- the Azure connection is only reliably deployable after the OCI FastConnect side is fully ready
- Terraform ordering alone does not guarantee partner-side operational readiness

The intended flow is:

1. apply with `enabled: false`
2. wait for interconnect readiness
3. set `enabled: true`
4. apply again

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
