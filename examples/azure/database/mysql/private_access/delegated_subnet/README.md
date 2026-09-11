# Azure MySQL Private Access - Delegated Subnet Example

This example composes **Azure Database for MySQL Flexible Server** with delegated-subnet private access, Azure Bastion operator access, and a small private validation host in the same VNet.

It is reshaped into a reusable `foggykitchen-landing-zone-orchestrator` pattern and payload from the current `terraform-az-fk-mysql` delegated-subnet example.

## Architecture Overview

<img src="diagrams/azure_mysql_private_access_delegated_subnet_architecture.jpg" alt="Azure MySQL private access delegated subnet architecture" width="900"/>

**Figure 1:** Azure MySQL Flexible Server delegated-subnet private access with Azure Bastion access to a private validation host.

The `mysql_private_access` pattern composes one VNet with a validation host subnet, `AzureBastionSubnet`, one MySQL delegated subnet, one subnet-associated NSG, one Azure Bastion host, one Private DNS Zone linked to the VNet, and one MySQL Flexible Server with public network access disabled.

## What This Example Deploys

- one Resource Group
- one VNet
- one client subnet
- one `AzureBastionSubnet`
- one delegated MySQL subnet
- one NSG associated to both subnets
- one Azure Bastion host for SSH access to the private validation host
- one Private DNS Zone linked to the VNet
- one MySQL Flexible Server using delegated-subnet private access
- one MySQL database
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
nc -vz <mysql-flexible-server-fqdn> 3306
mysql --host=<mysql-flexible-server-fqdn> --port=3306 --user=mysqladmin --ssl-mode=REQUIRED --database=foggydb --password
```

Expected result:

- TCP port `3306` is reachable from the validation host
- MySQL resolves through the VNet-linked Private DNS Zone
- the validation host has no public IP and operator SSH goes through Azure Bastion
- public network access on MySQL Flexible Server remains disabled
- no MySQL firewall rules are created

## Validation Result

Validation output from the deployed example through Azure Bastion:

```text
== client host ==
vm-fk-mysql-client

== client addresses ==
10.150.10.4

== mysql dns ==
10.150.20.4     fk-mysql-private-dev.fk-azure-mysql-private-access-dev.mysql.database.azure.com fk-mysql-private-dev.mysql.database.azure.com

== mysql tcp 3306 ==
Connection to fk-mysql-private-dev.mysql.database.azure.com (10.150.20.4) 3306 port [tcp/mysql] succeeded!
```

## Azure Portal Verification

<img src="diagrams/azure_mysql_private_access_delegated_subnet_resource_group_overview.jpg" alt="Resource Group overview" width="900"/>

**Figure 2.** Resource Group overview after deployment.

<img src="diagrams/azure_mysql_private_access_delegated_subnet_vnet_subnets.jpg" alt="VNet subnets" width="900"/>

**Figure 3.** VNet subnets for client, Bastion, and MySQL delegated private access.

<img src="diagrams/azure_mysql_private_access_delegated_subnet_mysql_networking.jpg" alt="MySQL networking" width="900"/>

**Figure 4.** MySQL Flexible Server networking with public access disabled.

<img src="diagrams/azure_mysql_private_access_delegated_subnet_private_dns_zone.jpg" alt="Private DNS Zone" width="900"/>

**Figure 5.** Private DNS Zone linked to the VNet.

<img src="diagrams/azure_mysql_private_access_delegated_subnet_bastion_overview.jpg" alt="Azure Bastion overview" width="900"/>

**Figure 6.** Azure Bastion used for operator access to the private validation host.

<img src="diagrams/azure_mysql_private_access_delegated_subnet_nsg_rules.jpg" alt="NSG rules" width="900"/>

**Figure 7.** NSG rules for Bastion SSH and MySQL reachability.

## Destroy

```bash
tofu destroy
```

## Notes

- `mysql_admin_password` and `admin_ssh_public_key` are sensitive Terraform variables and are injected into `landing-zone.yaml` with `templatefile`.
- This delegated-subnet variant does not configure Microsoft Entra authentication, customer-managed keys, or Azure Monitor diagnostics.
- Private Endpoint mode, richer app-to-data topologies, cross-region replicas, disaster recovery, schema bootstrap, and governance belong in later PRs or the private blueprint layer.
- `terraform-az-fk-compute v0.3.5` deploys the validation host with a private NIC. Azure Bastion provides the operator access path.

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
