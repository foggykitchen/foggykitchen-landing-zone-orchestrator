# Azure SQL Private Access Pattern

This pattern composes Azure networking, Azure Bastion, Private DNS, subnet-level NSG rules, Azure SQL Database, Private Endpoint, and a lightweight validation host into a public reference architecture for **private Azure SQL access**.

It is intentionally scoped to a **single-region Private Endpoint Azure SQL** scenario:

- one VNet with a client subnet, `AzureBastionSubnet`, and a Private Endpoint subnet
- one NSG associated to the client and Private Endpoint subnets
- one Azure Bastion host used for operator SSH access to the private validation host
- one Azure SQL logical server with public network access disabled
- one Azure SQL database
- one Private DNS Zone linked to the VNet
- one Private Endpoint using subresource `sqlServer`
- one lightweight compute host used to validate private TCP `1433` reachability

It does **not** include:

- Microsoft Entra administrator configuration
- transparent data encryption with a customer-managed key
- Azure Monitor diagnostic settings
- MySQL, PostgreSQL, Cosmos DB, or other database engines
- cross-region replica, disaster recovery, migration, schema bootstrap, or data loading logic
- hub-spoke app-to-data, multi-spoke, or governance topology

Those richer application, governance, and platform concerns belong in the private blueprint layer.

## Payload Scope

The pattern consumes:

- `architecture.private_access.mode`, currently only `private_endpoint`
- `architecture.network.vnet`
- `architecture.network.client_subnet`
- `architecture.network.bastion_subnet`
- `architecture.network.private_endpoint_subnet`
- `workload.client`
- `data.sql.server`
- `data.sql.database`

Optional `data.sql.entra`, `data.sql.cmk`, and `data.sql.diagnostics` blocks are decoded defensively but rejected by this pattern until a secure variant wires them explicitly.

## Private Endpoint Settings

- subresource name: `sqlServer`
- Private DNS Zone: `privatelink.database.windows.net`

## Example

- [`examples/azure/database/sql/private_access/private_endpoint`](../../../examples/azure/database/sql/private_access/private_endpoint/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
