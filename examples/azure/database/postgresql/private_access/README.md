# Azure PostgreSQL Private Access Examples

This scenario family focuses on PostgreSQL Flexible Server private access. It includes both delegated-subnet private access and Private Endpoint access variants.

## Available Variants

- [delegated_subnet](delegated_subnet/README.md) - delegated-subnet private access with one VNet, one client subnet, `AzureBastionSubnet`, one delegated database subnet, one NSG, one Azure Bastion host, one Private DNS Zone, and one validation host.
- [private_endpoint](private_endpoint/README.md) - Private Endpoint access with one VNet, one client subnet, `AzureBastionSubnet`, one Private Endpoint subnet, one NSG, one Azure Bastion host, one Private DNS Zone, and one validation host.

## Deferred

- secure variant with Microsoft Entra authentication, customer-managed keys, and diagnostics
- Azure SQL Database, MySQL, and Cosmos DB variants outside this PostgreSQL scenario family
- app-to-data, multi-spoke, governance, and disaster recovery blueprint tiers

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
