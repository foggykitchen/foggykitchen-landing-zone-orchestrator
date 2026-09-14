# Azure Cosmos DB Private Access Pattern

This pattern composes a minimal **Azure Cosmos DB SQL API** private-access landing zone from FoggyKitchen modules.

It is intentionally scoped to one private-access mode:

- **Private Endpoint** for Cosmos DB SQL API using subresource `Sql`

## What It Builds

- one Resource Group
- one VNet
- one client subnet
- one `AzureBastionSubnet`
- one Private Endpoint subnet
- one NSG associated with the client and Private Endpoint subnets
- one Azure Bastion host for SSH access to the private validation host
- one Private DNS Zone linked to the VNet
- one Cosmos DB account with public network access disabled
- one Cosmos DB SQL database
- one Cosmos DB SQL container
- one Private Endpoint and Private DNS Zone Group
- one private validation host for DNS and TCP `443` checks

## Payload Contract

The pattern accepts a single `payload_file` input and decodes the YAML payload in `locals.tf`.

The payload shape follows the database private-access examples:

- `landing_zone`
- `cloud`
- `architecture.network`
- `architecture.private_access.mode`
- `workload.client`
- `data.cosmosdb`

`architecture.private_access.mode` defaults to `private_endpoint`. Any other value fails with a clear error.

## Cosmos DB Scope

This pattern creates a basic Cosmos DB SQL API account:

- `kind = "GlobalDocumentDB"`
- one region in `geo_locations`
- `consistency_policy.consistency_level = "Session"`
- one SQL database
- one SQL container with a partition key
- `public_network_access_enabled = false`
- no IP firewall rules

## Private Endpoint Settings

The Private Endpoint uses:

- subresource: `Sql`
- Private DNS Zone: `privatelink.documents.azure.com`

These values are verified against current Azure Cosmos DB Private Link documentation and the `terraform-az-fk-cosmosdb` `v1.0.0` Private Endpoint example.

## Deliberately Excluded

This public orchestrator pattern does not implement:

- secure variant controls such as local-auth disablement, Cosmos DB data-plane RBAC assignments, managed identity, customer-managed keys, or diagnostics
- multi-region Cosmos DB accounts, cross-region failover, or disaster recovery
- MongoDB, Cassandra, Gremlin, or Table APIs
- app-to-data, hub-spoke, multi-spoke, centralized inspection, schema bootstrap, or governance concerns

Those richer concerns belong in later PRs or in the private blueprint layer.

## Example

- [Cosmos DB Private Endpoint example](../../../examples/azure/database/cosmosdb/private_access/private_endpoint/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
