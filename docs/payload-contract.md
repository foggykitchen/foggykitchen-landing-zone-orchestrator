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
- optional `routing`
- `security`
- `nat_gateway`
- `bastion`
- optional `private_dns`
- optional `compute`
- optional `load_balancer`

For NAT naming, the Azure hub-and-spoke pattern also accepts optional maps:

- `nat_gateway.names.<vnet_key>`
- `nat_gateway.public_ip_names.<vnet_key>`

When router-VM transit is used, the compute payload may also provide:

- `compute.instances.<name>.nic_nsg_name`

When `routing` is used for explicit transit, the Azure hub-and-spoke pattern also accepts:

- `routing.route_tables.<name>.subnet_refs`
- `routing.route_tables.<name>.routes[]`
- `routing.route_tables.<name>.routes[].next_hop_vm_ref`

Example:

```yaml
routing:
  enabled: true
  route_tables:
    rt-app-backend:
      subnet_refs:
        - app.backend
      routes:
        - name: to-data-via-router
          address_prefix: 10.30.0.0/16
          next_hop_type: VirtualAppliance
          next_hop_vm_ref: hubrouter
```

`private_endpoint` extends that with:

- `storage`
- `private_endpoints`
- optional `compute_storage_mounts`

For private DNS, a more explicit contract is:

- `private_dns.zones[].name`
- `private_dns.zones[].link_to_vnets`

Example:

```yaml
private_dns:
  enabled: true
  zones:
    - name: privatelink.file.core.windows.net
      link_to_vnets:
        - app
```

If the new per-zone structure is not used, the current Azure hub-and-spoke pattern falls back to the older shared-link behavior for backward compatibility.

For routed private endpoint consumption scenarios, the Azure private endpoint pattern also accepts:

- `compute_storage_mounts.enabled`
- `compute_storage_mounts.name`
- `compute_storage_mounts.subnet_ref`
- `compute_storage_mounts.mount_azure_files.enabled`
- `compute_storage_mounts.mount_azure_files.share_name`
- `compute_storage_mounts.mount_azure_files.mount_path`

Example:

```yaml
compute_storage_mounts:
  enabled: true
  name: vm-fk-app-pe-01
  subnet_ref: app.backend
  size: Standard_B2s
  private_ip_address_allocation: Static
  private_ip_address: 10.20.2.4
  mount_azure_files:
    enabled: true
    share_name: shared
    mount_path: /mnt/azurefiles
```

Why this sits outside generic `compute.instances`:

- the VM depends on Storage Account outputs
- cloud-init must be rendered after the Storage Account and file share exist
- this keeps the shared `hub_spoke` pattern storage-agnostic while still allowing a storage-aware consumer VM in the private endpoint pattern

Operational note for local applies:

- the example wrapper may also accept a `provisioner_public_ip` input
- this is not architecture intent and therefore does not live in YAML
- it exists only to allow the local OpenTofu runner to create Azure Files data-plane resources while the Storage Account remains locked down by network rules

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
