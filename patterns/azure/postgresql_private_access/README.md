# Azure PostgreSQL Private Access Pattern

This pattern composes Azure networking, Azure Bastion, Private DNS, subnet-level NSG rules, PostgreSQL Flexible Server, and a lightweight validation host into a public reference architecture for **private PostgreSQL access**.

It is intentionally scoped to **single-region PostgreSQL private access** scenarios:

- one VNet with a client subnet, `AzureBastionSubnet`, and either a delegated database subnet or a Private Endpoint subnet
- one NSG associated to the client and database-facing subnets
- one Azure Bastion host used for operator SSH access to the private validation host
- one Azure Database for PostgreSQL Flexible Server with public network access disabled
- one Private DNS Zone linked to the VNet
- optional PostgreSQL Private Endpoint and DNS Zone Group when `private_access.mode = "private_endpoint"`
- one lightweight compute host used to validate private TCP `5432` reachability

It does **not** include:

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
- `architecture.network.delegated_subnet` when `private_access.mode = "delegated_subnet"`
- `architecture.network.private_endpoint_subnet` when `private_access.mode = "private_endpoint"`
- `workload.client`
- `data.postgresql.server`
- `data.postgresql.database`

Optional `data.postgresql.entra`, `data.postgresql.cmk`, and `data.postgresql.diagnostics` blocks are decoded defensively but rejected by this pattern until a secure variant wires them explicitly.

## Examples

- [`examples/azure/database/postgresql/private_access/delegated_subnet`](../../../examples/azure/database/postgresql/private_access/delegated_subnet/README.md)
- [`examples/azure/database/postgresql/private_access/private_endpoint`](../../../examples/azure/database/postgresql/private_access/private_endpoint/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
