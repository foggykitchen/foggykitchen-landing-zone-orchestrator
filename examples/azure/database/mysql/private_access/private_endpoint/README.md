# Azure MySQL Private Access - Private Endpoint Example

This example composes **Azure Database for MySQL Flexible Server** with Private Endpoint access, Azure Bastion operator access, and a small private validation host in the same VNet.

It extends the reusable `foggykitchen-landing-zone-orchestrator` `mysql_private_access` pattern with the MySQL Flexible Server Private Link path.

## Architecture Overview

<img src="diagrams/azure_mysql_private_access_private_endpoint_architecture.jpg" alt="Azure MySQL private access Private Endpoint architecture" width="900"/>

**Figure 1.** Azure MySQL Flexible Server Private Endpoint private access with Azure Bastion access to a private validation host.

The `mysql_private_access` pattern composes one VNet with a validation host subnet, `AzureBastionSubnet`, one Private Endpoint subnet, one subnet-associated NSG, one Azure Bastion host, one Private DNS Zone linked to the VNet, one MySQL Flexible Server with public network access disabled, one MySQL database, and one Private Endpoint with DNS Zone Group.

## What This Example Deploys

- one Resource Group
- one VNet
- one client subnet
- one `AzureBastionSubnet`
- one Private Endpoint subnet
- one NSG associated to the client and Private Endpoint subnets
- one Azure Bastion host for SSH access to the private validation host
- one Private DNS Zone linked to the VNet
- one MySQL Flexible Server with public network access disabled
- one MySQL database
- one Private Endpoint and Private DNS Zone Group
- one lightweight compute host used to validate private TCP `3306` reachability

## Pattern

- [`patterns/azure/mysql_private_access`](../../../../../../patterns/azure/mysql_private_access/README.md)

## Files

- [landing-zone.yaml](landing-zone.yaml)
- [main.tf](main.tf)
- [providers.tf](providers.tf)
- [variables.tf](variables.tf)
- [outputs.tf](outputs.tf)
- [terraform.tfvars.example](terraform.tfvars.example)

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu plan
tofu apply
```

Replace the placeholder values in `terraform.tfvars` before planning.

## Validation Flow

After apply, use the `validation_host.ssh_command` output to connect to the private validation host through Azure Bastion, then validate MySQL reachability:

```bash
az network bastion ssh --name <bastion-name> --resource-group <resource-group-name> --target-resource-id <validation-vm-id> --auth-type ssh-key --username azureuser --ssh-key <path-to-private-key>
getent hosts <mysql-flexible-server-fqdn>
nc -vz <mysql-flexible-server-fqdn> 3306
mysql --host=<mysql-flexible-server-fqdn> --port=3306 --user=mysqladmin --ssl-mode=REQUIRED --database=foggydb --password
```

Expected result:

- TCP port `3306` is reachable from the validation host
- MySQL resolves through the VNet-linked Private DNS Zone
- the validation host has no public IP and operator SSH goes through Azure Bastion
- public network access on MySQL Flexible Server remains disabled
- no MySQL firewall rules are created

## Azure Portal Verification

<img src="diagrams/azure_mysql_private_access_private_endpoint_resource_group_overview.jpg" alt="Resource Group overview" width="900"/>

**Figure 2.** Resource Group overview after deployment.

<img src="diagrams/azure_mysql_private_access_private_endpoint_vnet_subnets.jpg" alt="VNet subnets" width="900"/>

**Figure 3.** VNet subnets for client, Bastion, and MySQL Private Endpoint access.

<img src="diagrams/azure_mysql_private_access_private_endpoint_mysql_overview.jpg" alt="MySQL Flexible Server overview" width="900"/>

**Figure 4.** MySQL Flexible Server overview.

<img src="diagrams/azure_mysql_private_access_private_endpoint_mysql_networking.jpg" alt="MySQL Flexible Server networking" width="900"/>

**Figure 5.** MySQL Flexible Server networking with public access disabled and Private Endpoint access enabled.

<img src="diagrams/azure_mysql_private_access_private_endpoint_private_endpoint.jpg" alt="Private Endpoint overview" width="900"/>

**Figure 6.** Private Endpoint connected to the MySQL Flexible Server.

<img src="diagrams/azure_mysql_private_access_private_endpoint_private_endpoint_dns.jpg" alt="Private Endpoint DNS configuration" width="900"/>

**Figure 7.** Private Endpoint DNS configuration for MySQL Flexible Server.

<img src="diagrams/azure_mysql_private_access_private_endpoint_private_dns_zone_records.jpg" alt="Private DNS Zone records" width="900"/>

**Figure 8.** Private DNS Zone records for the MySQL Private Endpoint.

<img src="diagrams/azure_mysql_private_access_private_endpoint_private_dns_zone_vnet_connection.jpg" alt="Private DNS Zone VNet connection" width="900"/>

**Figure 9.** Private DNS Zone VNet link for private MySQL name resolution.

<img src="diagrams/azure_mysql_private_access_private_endpoint_bastion_overview.jpg" alt="Azure Bastion overview" width="900"/>

**Figure 10.** Azure Bastion used for operator access to the private validation host.

<img src="diagrams/azure_mysql_private_access_private_endpoint_nsg_rules.jpg" alt="NSG rules" width="900"/>

**Figure 11.** NSG rules for Bastion SSH and MySQL reachability.

## Destroy

```bash
tofu destroy
```

## Notes

- `mysql_admin_password` and `admin_ssh_public_key` are sensitive Terraform variables and are injected into `landing-zone.yaml` with `templatefile`.
- This Private Endpoint variant does not configure Microsoft Entra authentication, customer-managed keys, or Azure Monitor diagnostics.
- The MySQL Flexible Server Private Endpoint target subresource is `mysqlServer`.
- The Private DNS Zone used by this variant is `privatelink.mysql.database.azure.com`.
- Richer app-to-data topologies, cross-region replicas, disaster recovery, schema bootstrap, and governance belong in later PRs or the private blueprint layer.
- `terraform-az-fk-compute v0.3.5` deploys the validation host with a private NIC. Azure Bastion provides the operator access path.

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
