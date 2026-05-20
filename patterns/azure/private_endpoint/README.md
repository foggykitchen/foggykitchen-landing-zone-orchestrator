# Azure Private Endpoint Pattern

This directory contains the shared **Azure private endpoint landing zone pattern** used by FoggyKitchen Landing Zone Orchestrator.

---

## 🎯 Purpose

The goal of this pattern is to extend the shared Azure hub-and-spoke foundation with:

- Storage Account deployment
- private access only
- Private Endpoint resources
- Private DNS integration
- optional routed consumer compute that mounts Azure Files through Private Link

---

## ✨ What The Pattern Builds

The pattern composes:

- the full `hub_spoke` Azure foundation
- one Azure Storage Account
- one or more Private Endpoints
- Private DNS zone bindings for private service resolution
- an optional `compute_storage_mounts` VM created after Storage Account provisioning

---

## 📂 Key Files

- [`main.tf`](main.tf)
- [`locals.tf`](locals.tf)
- [`variables.tf`](variables.tf)
- [`outputs.tf`](outputs.tf)
- [`versions.tf`](versions.tf)

This pattern is consumed by:

- [`examples/azure/networking/private_endpoint/storage_private_link`](../../../../examples/azure/networking/private_endpoint/storage_private_link/README.md)

---

## 🧩 Input Model

The pattern expects:

- `payload_file`

The payload is expected to include the baseline Azure networking contract plus:

- `storage`
- `private_endpoints`
- optional `compute_storage_mounts`

The payload is normalized in [`locals.tf`](locals.tf), where logical subnet references are resolved through the shared `hub_spoke` outputs.
When `compute_storage_mounts` is enabled, the pattern also renders a storage-aware cloud-init template after the Storage Account exists and then deploys a VM that can mount Azure Files over the private endpoint path.

---

## ⚠️ Current Notes

- this pattern reuses `hub_spoke` rather than duplicating the Azure networking foundation
- the current example focuses on Storage private access
- `compute_storage_mounts` exists because a VM that mounts Azure Files needs Storage Account outputs and therefore cannot be treated as an ordinary early-stage `hub_spoke` compute instance

---

## 📤 Outputs

The pattern exposes outputs for:

- all inherited `hub_spoke` foundation outputs
- Storage Account ID and name
- Storage file share names
- blob and file endpoints
- Private Endpoint IDs
- Private Endpoint private IPs

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
