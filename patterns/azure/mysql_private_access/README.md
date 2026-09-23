# Azure MySQL Private Access Pattern

This pattern composes Azure networking, Azure Bastion, Private DNS, subnet-level NSG rules, Azure Database for MySQL Flexible Server, and a lightweight validation host into a public reference architecture for **private MySQL access**.

It is intentionally scoped to **single-region MySQL private access** scenarios:

- one VNet with a client subnet, `AzureBastionSubnet`, and either a delegated MySQL subnet or a Private Endpoint subnet
- one NSG associated to the client and database-facing subnets
- one Azure Bastion host used for operator SSH access to the private validation host
- one Azure Database for MySQL Flexible Server with public network access disabled
- one MySQL database
- one Private DNS Zone linked to the VNet
- optional MySQL Private Endpoint and DNS Zone Group when `private_access.mode = "private_endpoint"`
- one lightweight compute host used to validate private TCP `3306` reachability

It does **not** include:

- Microsoft Entra authentication or administrator configuration
- customer-managed key encryption
- Azure Monitor diagnostic settings
- PostgreSQL, Azure SQL Database, Cosmos DB, or other database engines
- cross-region replica, disaster recovery, migration, schema bootstrap, or data loading logic
- hub-spoke app-to-data, multi-spoke, or governance topology

Those richer application, governance, and platform concerns belong in the private blueprint layer.

## Payload Scope

The pattern consumes:

- `architecture.private_access.mode`, currently `delegated_subnet` or `private_endpoint`
- `architecture.network.vnet`
- `architecture.network.client_subnet`
- `architecture.network.bastion_subnet`
- `architecture.network.delegated_subnet` when `private_access.mode = "delegated_subnet"`
- `architecture.network.private_endpoint_subnet` when `private_access.mode = "private_endpoint"`
- `workload.client`
- `data.mysql.server`
- `data.mysql.database`

Optional `data.mysql.entra`, `data.mysql.cmk`, and `data.mysql.diagnostics` blocks are decoded defensively but rejected by this pattern until a secure variant wires them explicitly.

## Delegated-Subnet Settings

- delegated subnet service: `Microsoft.DBforMySQL/flexibleServers`
- Private DNS Zone: a zone ending with `mysql.database.azure.com`

## Private Endpoint Settings

- Private Endpoint subresource: `mysqlServer`
- Private DNS Zone: `privatelink.mysql.database.azure.com`

## Examples

- [`examples/azure/database/mysql/private_access/delegated_subnet`](../../../examples/azure/database/mysql/private_access/delegated_subnet/README.md)
- [`examples/azure/database/mysql/private_access/private_endpoint`](../../../examples/azure/database/mysql/private_access/private_endpoint/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
