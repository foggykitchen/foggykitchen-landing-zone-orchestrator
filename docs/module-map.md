# Module Map

This document maps the current repository patterns to the FoggyKitchen modules they compose.

---

## 🎯 Purpose

The goal of this map is to show how the repository turns individual modules into **coherent architecture patterns**.

---

## ☁️ Azure Core Modules

| Module | Role in the landing zone |
| --- | --- |
| `terraform-az-fk-vnet` | Network boundary |
| `terraform-az-fk-vnet-peering` | Connectivity contract |
| `terraform-az-fk-routing` | Traffic control and UDR layer |
| `terraform-az-fk-nsg` | Security boundary |
| `terraform-az-fk-public-ip` | Public identity for platform egress |
| `terraform-az-fk-natgw` | Outbound identity and egress boundary |
| `terraform-az-fk-bastion` | Secure operator access |
| `terraform-az-fk-private-dns` | Private name resolution layer |
| `terraform-az-fk-compute` | Workload layer |
| `terraform-az-fk-loadbalancer` | Public traffic entry contract |
| `terraform-az-fk-storage` | Storage service layer |
| `terraform-az-fk-private-endpoint` | Private service exposure |
| `terraform-az-fk-firewall` | Central inspection and transit boundary |

---

## 🧩 Azure Pattern Usage

### `patterns/azure/hub_spoke`

Uses:

- `terraform-az-fk-vnet`
- `terraform-az-fk-vnet-peering`
- `terraform-az-fk-routing`
- `terraform-az-fk-nsg`
- `terraform-az-fk-public-ip`
- `terraform-az-fk-natgw`
- `terraform-az-fk-bastion`
- `terraform-az-fk-private-dns`
- `terraform-az-fk-compute`

Notes:

- internal load balancer is currently implemented directly with AzureRM

### `patterns/azure/private_endpoint`

Uses:

- everything from `hub_spoke` indirectly
- `terraform-az-fk-storage`
- `terraform-az-fk-private-endpoint`

### `patterns/azure/firewall_transit`

Uses:

- `terraform-az-fk-vnet`
- `terraform-az-fk-vnet-peering`
- `terraform-az-fk-routing`
- `terraform-az-fk-public-ip`
- `terraform-az-fk-firewall`
- `terraform-az-fk-compute`

---

## ☁️ OCI Core Modules

| Module | Role in the landing zone |
| --- | --- |
| `terraform-oci-fk-vcn` | Network boundary |
| `terraform-oci-fk-lpg` | Same-region local peering |
| `terraform-oci-fk-drg` | Strategic routing and transit layer |
| `terraform-oci-fk-compute` | Workload layer |
| `terraform-oci-fk-loadbalancer` | Traffic entry and distribution contract |

---

## 🧩 OCI Pattern Usage

### `patterns/oci/drg_hub_spoke`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-drg`
- `terraform-oci-fk-compute`
- `terraform-oci-fk-loadbalancer`

### `patterns/oci/lpg_local_peering`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-lpg`
- `terraform-oci-fk-compute`
- `terraform-oci-fk-loadbalancer`

---

## 🌉 Multicloud Pattern Usage

### `patterns/multicloud/oci_azure_interconnect`

Uses FoggyKitchen modules for foundations:

- `terraform-az-fk-vnet`
- `terraform-az-fk-nsg`
- `terraform-az-fk-compute`
- `terraform-oci-fk-vcn`
- `terraform-oci-fk-compute`

Uses raw provider resources for interconnect edge components:

- Azure ExpressRoute Circuit
- Azure Virtual Network Gateway
- Azure Virtual Network Gateway Connection
- OCI DRG edge resources
- OCI FastConnect Virtual Circuit

This is currently intentional and transitional.

---

## ⚠️ Current Gaps

The current module map does not yet include dedicated FoggyKitchen modules for:

- Azure internal load balancer patterns
- Azure ExpressRoute edge resources
- OCI FastConnect edge resources
- OCI interconnect-specific DRG edge abstractions

Those are natural future expansion points for the module catalog.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
