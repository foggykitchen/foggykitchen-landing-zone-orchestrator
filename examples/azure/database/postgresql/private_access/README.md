# Azure PostgreSQL Private Access Examples

This scenario family focuses on PostgreSQL Flexible Server private access. The first variant uses delegated-subnet private access; a Private Endpoint variant is planned.

## Available Variants

- [delegated_subnet](delegated_subnet/README.md) - delegated-subnet private access with one VNet, one client subnet, `AzureBastionSubnet`, one delegated database subnet, one NSG, one Azure Bastion host, one Private DNS Zone, and one validation host.

## Deferred

- Private Endpoint mode variant
- secure variant with Microsoft Entra authentication, customer-managed keys, and diagnostics
- MySQL, Azure SQL Database, and Cosmos DB
- app-to-data, multi-spoke, governance, and disaster recovery blueprint tiers

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
