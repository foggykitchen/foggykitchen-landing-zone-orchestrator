# Payload Contract

This document explains the **payload design philosophy and contract shape** used by the orchestrator.

---

## 🎯 Purpose

The payload contract is **architecture-first**.

It should describe:

- what pattern the user wants
- where workloads should live
- which features are enabled
- what routing and security intent should apply

It should not try to become a raw dump of every low-level provider argument.

---

## 🧠 General Rules

1. Module sources are never configurable from YAML.
2. Payloads describe intent, not module implementation details.
3. Feature flags may enable or disable whole capabilities.
4. Workload placement uses stable logical references such as `subnet_ref`.
5. Payload readers should prefer logical names over cloud resource IDs where possible.

---

## 🔗 Reference Style

String references use dotted notation when a pattern needs to resolve a logical placement or dependency.

Examples:

- `hub.bastion`
- `app.frontend`
- `app.backend`
- `data.database`
- `data.private_endpoints`
- `spoke1.workload`
- `spoke2.workload`

These references are resolved in `locals.tf` into cloud-specific subnet IDs, CIDRs, or related resource targets.

---

## ☁️ Azure Payload Shape

Common Azure payload sections may include:

- `landing_zone`
- `cloud`
- `architecture`
- `features`
- `networking`
- `peering`
- `routing`
- `security`
- `nat_gateway`
- `bastion`
- `private_dns`
- `compute`
- `load_balancer`
- `storage`
- `private_endpoints`
- `firewall`

Not every Azure pattern uses all sections.

### Example Usage by Pattern

`hub_spoke` focuses on:

- `features`
- `networking`
- `peering`
- `routing`
- `security`
- `nat_gateway`
- `bastion`
- `private_dns`
- `compute`
- `load_balancer`

`private_endpoint` extends that with:

- `storage`
- `private_endpoints`

`firewall_transit` focuses on:

- `networking`
- `peering`
- `firewall`
- `routing`
- `compute`

---

## ☁️ OCI Payload Shape

Common OCI payload sections may include:

- `landing_zone`
- `cloud`
- `architecture`
- `networking`
- `connectivity`
- `compute`
- `load_balancer`

### Example Usage by Pattern

`drg_hub_spoke` focuses on:

- multi-VCN `networking`
- `connectivity.drg`
- private `compute`
- private `load_balancer`

`lpg_local_peering` focuses on:

- multi-VCN `networking`
- `connectivity.lpg`
- private `compute`
- private `load_balancer`

---

## 🌉 Multicloud Payload Shape

The multicloud interconnect payload is intentionally split by cloud:

- `landing_zone`
- `azure`
- `oci`
- `interconnect`

Why:

- keeps cloud-local concerns separate
- makes cross-cloud edge resources explicit
- avoids pretending that Azure and OCI share the same schema at every level

The interconnect pattern also introduces a staged control flag:

- `interconnect.azure.connection.enabled`

This exists because the final Azure gateway connection should only be created after OCI FastConnect and Azure ExpressRoute are fully ready.

---

## ⚠️ Contract Philosophy

The payload contract should evolve carefully.

Good evolution:

- add a new section for a clearly separate capability
- add a new logical reference type
- add a new pattern-specific subtree

Bad evolution:

- exposing raw module source strings
- turning payloads into unstructured provider argument bags
- forcing unrelated patterns into a single schema for the sake of uniformity

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
