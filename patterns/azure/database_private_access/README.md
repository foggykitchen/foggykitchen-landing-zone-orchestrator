# Azure Database Private Access Pattern

This pattern composes Azure networking, Azure Bastion, Private DNS, subnet-level NSG rules, PostgreSQL Flexible Server, and a lightweight validation host into a public reference architecture for **private PostgreSQL access**.

It is intentionally scoped to a **single-region delegated-subnet PostgreSQL** scenario:

- one VNet with a client subnet, `AzureBastionSubnet`, and a delegated database subnet
- one NSG associated to the client and database subnets
- one Azure Bastion host used for operator SSH access to the private validation host
- one Azure Database for PostgreSQL Flexible Server with public network access disabled
- one Private DNS Zone linked to the VNet
- one lightweight compute host used to validate private TCP `5432` reachability

It does **not** include:

- PostgreSQL Private Endpoint mode
- a secure variant with Microsoft Entra authentication, customer-managed keys, or diagnostic settings
- MySQL, Azure SQL Database, Cosmos DB, or other database engines
- cross-region replica, disaster recovery, migration, schema bootstrap, or data loading logic
- hub-spoke app-to-data, multi-spoke, or governance topology

Those richer application, governance, and platform concerns belong in the private blueprint layer.

## Payload Scope

The pattern consumes:

- `architecture.private_access.mode`, currently only `delegated_subnet`
- `architecture.network.vnet`
- `architecture.network.client_subnet`
- `architecture.network.bastion_subnet`
- `architecture.network.delegated_subnet`
- `workload.client`
- `data.postgresql.server`
- `data.postgresql.database`

Optional `data.postgresql.entra`, `data.postgresql.cmk`, and `data.postgresql.diagnostics` blocks are decoded defensively but rejected by this basic pattern until a secure variant wires them explicitly.

## Example

- [`examples/azure/database/postgresql/private_access/basic`](../../../examples/azure/database/postgresql/private_access/basic/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
