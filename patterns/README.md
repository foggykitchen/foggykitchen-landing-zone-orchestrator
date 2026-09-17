# Patterns

This directory contains the **shared HCL orchestration patterns** used by FoggyKitchen Landing Zone Orchestrator.

---

## 🎯 Purpose

Patterns are the reusable implementation layer of the repository.

They are responsible for:

- normalizing YAML payload input
- resolving logical references
- composing FoggyKitchen modules
- exposing a stable pattern interface to examples

Examples under `examples/` should stay thin and delegate architecture logic to the shared patterns in this directory.

---

## 📂 Pattern Families

### Azure

- [README](azure/README.md)
- [hub_spoke](azure/hub_spoke)
- [private_endpoint](azure/private_endpoint)
- [firewall_transit](azure/firewall_transit)
- [aks_basic](azure/aks_basic)
- [aks_private_acr](azure/aks_private_acr)
- [postgresql_private_access](azure/postgresql_private_access)
- [sql_private_access](azure/sql_private_access)
- [mysql_private_access](azure/mysql_private_access)
- [cosmosdb_private_access](azure/cosmosdb_private_access)

### OCI

- [README](oci/README.md)
- [drg_cross_region](oci/drg_cross_region)
- [lpg_local_peering](oci/lpg_local_peering)
- [devops_build_only](oci/devops_build_only)
- [devops_build_and_deploy_oke](oci/devops_build_and_deploy_oke)

### Multicloud

- [README](multicloud/README.md)

---

## 🧭 How To Read This Directory

Recommended order:

1. start with [docs/architecture.md](../docs/architecture.md)
2. review [docs/payload-contract.md](../docs/payload-contract.md)
3. inspect the relevant pattern directory
4. compare it with one of the thin example wrappers under `examples/`

---

## ⚠️ Current Notes

- `azure/hub_spoke` is the shared base for the Azure networking-oriented patterns
- `azure/private_endpoint` extends the shared Azure networking foundation
- `azure/aks_basic` adds a teaser-tier private AKS baseline with Azure Bastion, NAT Gateway egress, and a private jump host
- `azure/aks_private_acr` extends the AKS teaser tier with ACR Private Endpoint and Private DNS access
- `azure/postgresql_private_access` keeps PostgreSQL delegated-subnet and Private Endpoint variants minimal and self-contained
- `azure/sql_private_access` adds the first Azure database Private Endpoint pattern while keeping the network self-contained
- `azure/mysql_private_access` mirrors the delegated-subnet database shape for MySQL Flexible Server
- `azure/cosmosdb_private_access` adds Cosmos DB SQL API Private Endpoint access with a self-contained validation network
- advanced multicloud implementations are intentionally distributed outside this public repository

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
