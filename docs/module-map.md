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
| `terraform-az-fk-loadbalancer` | Public and private traffic entry contract |
| `terraform-az-fk-storage` | Storage service layer |
| `terraform-az-fk-private-endpoint` | Private service exposure |
| `terraform-az-fk-firewall` | Central inspection and transit boundary |

---

## 🧩 Azure Pattern Usage

### `patterns/azure/hub_spoke`

Uses:

- `terraform-az-fk-vnet`
- `terraform-az-fk-vnet-peering`
- `terraform-az-fk-nsg`
- `terraform-az-fk-public-ip`
- `terraform-az-fk-natgw`
- `terraform-az-fk-bastion`
- `terraform-az-fk-private-dns`
- `terraform-az-fk-compute`
- `terraform-az-fk-loadbalancer`

Optional by payload:

- `terraform-az-fk-routing`

### `patterns/azure/private_endpoint`

Uses:

- everything from `hub_spoke` indirectly
- `terraform-az-fk-storage`
- `terraform-az-fk-private-endpoint`
- optionally `terraform-az-fk-compute` a second time for `compute_storage_mounts`

Why the extra compute call:

- generic `hub_spoke` compute is storage-agnostic
- a consumer VM that mounts Azure Files needs Storage Account outputs
- the private endpoint pattern therefore creates that VM after Storage Account provisioning when `compute_storage_mounts` is enabled

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
| `terraform-oci-fk-dns-steering` | Multiregion DNS failover and traffic steering layer |
| `terraform-oci-fk-ocir` | OCI Container Registry repository layer |
| `terraform-oci-fk-oke` | Kubernetes platform layer |
| `terraform-oci-fk-policy` | IAM and dynamic-group policy layer |
| `terraform-oci-fk-api-gateway` | Public API ingress and route publishing layer |
| `terraform-oci-fk-function` | OCI Functions application and function packaging layer |
| `terraform-oci-fk-objectstorage` | Object Storage bucket and namespace-facing ingestion layer |
| `terraform-oci-fk-event` | OCI Events rule and action routing layer |
| `terraform-oci-fk-streaming` | Event buffer and stream pool layer |
| `terraform-oci-fk-sch` | Service Connector Hub event routing layer |
| `terraform-oci-fk-adb` | Autonomous Database persistence layer |
| `terraform-oci-fk-devops` | Shared OCI DevOps resources such as project, connection, repositories, artifacts, and deploy environments |
| `terraform-oci-fk-devops-pipeline` | Build and deploy pipeline graph layer |

---

## 🧩 OCI Pattern Usage

### `patterns/oci/drg_cross_region`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-drg`

Why this pattern is narrower:

- it focuses on OCI-native cross-region DRG and RPC composition
- it intentionally leaves compute and load balancer concerns out of scope
- it maps more directly to the `terraform-oci-fk-drg` remote peering reference scenario

### `patterns/oci/lpg_local_peering`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-lpg`
- `terraform-oci-fk-compute`
- `terraform-oci-fk-loadbalancer`

### `patterns/oci/multiregion_compute_failover`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-drg`
- `terraform-oci-fk-compute`
- `terraform-oci-fk-loadbalancer`
- `terraform-oci-fk-dns-steering`

Focus:

- primary and standby regional sites with separate OCI VCNs
- DRG remote peering to keep the sites network-connected
- one load balancer and one instance pool per site
- lightweight warm-standby sizing by payload
- OCI DNS Steering failover across the public load balancer endpoints
- public stateless DR pattern without storage or database replication

### `patterns/oci/devops_build_only`

Uses:

- `terraform-oci-fk-ocir`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-devops`
- `terraform-oci-fk-devops-pipeline`

Focus:

- OCI DevOps project and GitHub connection
- mirrored source repository
- build pipeline with `build` and `deliver` stages
- Docker image artifact delivery into OCIR
- IAM policies for DevOps dynamic-group access to Vault, repos, and DevOps resources

### `patterns/oci/devops_build_and_deploy_oke`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-oke`
- `terraform-oci-fk-ocir`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-devops`
- `terraform-oci-fk-devops-pipeline`

Focus:

- dual mirrored repositories for app and Helm sources
- build pipeline for image build and Helm chart packaging
- optional cascade trigger from build pipeline into deploy pipeline
- OKE deploy environment and Helm deployment stage
- Kubernetes-side OCIR pull secret provisioning

### `patterns/oci/authenticated_serverless_api`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-function`
- `terraform-oci-fk-api-gateway`

Focus:

- public API Gateway front door
- custom auth function for protected requests
- private backend function behind the authorizer
- lightweight serverless access pattern without persistence or async middleware

### `patterns/oci/event_driven_data_pipeline`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-api-gateway`
- `terraform-oci-fk-function`
- `terraform-oci-fk-streaming`
- `terraform-oci-fk-sch`
- `terraform-oci-fk-adb`

Focus:

- public API Gateway entry point into a private Functions application
- initiator function publishing into OCI Streaming
- Service Connector Hub consuming the stream and invoking the collector
- ADB bootstrap function plus final persistence into Autonomous Database
- end-to-end asynchronous data flow from HTTP request to stored database record

### `patterns/oci/bulk_ingestion_pipeline`

Uses:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-function`
- `terraform-oci-fk-objectstorage`
- `terraform-oci-fk-event`
- `terraform-oci-fk-streaming`
- `terraform-oci-fk-sch`
- `terraform-oci-fk-adb`

Focus:

- bucket-driven ingestion without an HTTP entry point
- OCI Events invoking the bulk loader function on object creation
- bulk expansion into per-record messages in OCI Streaming
- Service Connector Hub invoking the collector function
- ADB bootstrap plus final persistence into Autonomous Database

---

## ⚠️ Current Gaps

The current module map does not yet include dedicated FoggyKitchen modules for:

- Azure ExpressRoute edge resources
- OCI FastConnect edge resources
- OCI interconnect-specific DRG edge abstractions
- advanced multicloud blueprint composition in the private `foggykitchen-landing-zone-blueprint` repository

Those are natural future expansion points for the module catalog and premium blueprint layer.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
