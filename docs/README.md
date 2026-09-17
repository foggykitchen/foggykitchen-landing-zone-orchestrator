# Documentation

This directory contains the **supporting architecture documentation** for FoggyKitchen Landing Zone Orchestrator.

---

## 🎯 Purpose

The documents in this directory explain:

- the architecture model used by the orchestrator
- the main engineering decisions behind the repository
- how FoggyKitchen modules are mapped into shared patterns
- how the YAML payload contract is structured

They cover both:

- landing zone networking compositions for Azure and OCI
- Azure AKS teaser-tier compositions
- Azure private database compositions for PostgreSQL, MySQL, SQL Database, and Cosmos DB
- OCI private ADB access compositions
- OCI multiregion compute failover compositions
- OCI DevOps delivery compositions such as `build_only` and `build_and_deploy_oke`
- OCI Functions-based API and data patterns such as `authenticated_serverless_api`, `event_driven_data_pipeline`, and `bulk_ingestion_pipeline`

---

## 📚 Documents

- [Architecture](architecture.md)
- [Design Decisions](design-decisions.md)
- [Module Map](module-map.md)
- [Payload Contract](payload-contract.md)

---

## Azure Database Coverage

The public orchestrator currently includes Azure private database landing-zone patterns for:

| Engine | Pattern | Current private-access modes |
| --- | --- | --- |
| PostgreSQL Flexible Server | `patterns/azure/postgresql_private_access` | delegated subnet, Private Endpoint |
| Azure Database for MySQL Flexible Server | `patterns/azure/mysql_private_access` | delegated subnet |
| Azure SQL Database | `patterns/azure/sql_private_access` | Private Endpoint |
| Cosmos DB SQL API | `patterns/azure/cosmosdb_private_access` | Private Endpoint |

These patterns use self-contained single-region VNets with Azure Bastion and a private validation host. They do not reuse the broader `hub_spoke` topology.

## Azure AKS Coverage

The public orchestrator currently includes Azure AKS teaser-tier patterns:

| Scenario | Pattern | Current scope |
| --- | --- | --- |
| Private AKS basic | `patterns/azure/aks_basic` | single-region private AKS cluster with Azure Bastion, NAT Gateway egress, subnet NSGs, empty route table for `userDefinedRouting`, and a private jump host |
| Private AKS plus private ACR | `patterns/azure/aks_private_acr` | `aks_basic` shape plus ACR Premium, ACR Private Endpoint subresource `registry`, Private DNS Zone `privatelink.azurecr.io`, and `AcrPull` attachment |

The AKS patterns are intentionally narrower than the premium `aks_firewall_transit` blueprint. Azure Firewall transit, customer-managed keys, additional node pools, autoscaling, diagnostics, multi-region, and DR are outside these public patterns.

The public examples tree includes [examples/azure/aks/firewall_transit_basic](../examples/azure/aks/firewall_transit_basic/README.md) as a placeholder for the premium AKS firewall-transit blueprint. The implementation is distributed through the private `foggykitchen-landing-zone-blueprint` repository and requires a [FoggyKitchen Professional+ subscription](https://foggykitchen.com/membership).

---

## 🧭 Recommended Reading Order

1. [Architecture](architecture.md)
2. [Payload Contract](payload-contract.md)
3. [Module Map](module-map.md)
4. [Design Decisions](design-decisions.md)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
