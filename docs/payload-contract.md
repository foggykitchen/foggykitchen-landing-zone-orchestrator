# Payload Contract

This document explains the **payload design philosophy and contract shape** used by the orchestrator.

---

## 🎯 Purpose

The payload contract is **architecture-first**.

It should describe:

- what pattern the user wants
- where workloads should live
- which features are enabled
- what routing and security intent should apply

It should not try to become a raw dump of every low-level provider argument.

---

## 🧠 General Rules

1. Module sources are never configurable from YAML.
2. Payloads describe intent, not module implementation details.
3. Feature flags may enable or disable whole capabilities.
4. Workload placement uses stable logical references such as `subnet_ref`.
5. Payload readers should prefer logical names over cloud resource IDs where possible.

---

## 🔗 Reference Style

String references use dotted notation when a pattern needs to resolve a logical placement or dependency.

Examples:

- `hub.bastion`
- `app.frontend`
- `app.backend`
- `data.database`
- `data.private_endpoints`
- `spoke1.workload`
- `spoke2.workload`

These references are resolved in `locals.tf` into cloud-specific subnet IDs, CIDRs, or related resource targets.

---

## ☁️ Azure Payload Shape

Common Azure payload sections may include:

- `landing_zone`
- `cloud`
- `architecture`
- `features`
- `networking`
- `peering`
- `routing`
- `security`
- `nat_gateway`
- `bastion`
- `private_dns`
- `compute`
- `load_balancer`
- `storage`
- `private_endpoints`
- `firewall`
- `data`

Not every Azure pattern uses all sections.

### Example Usage by Pattern

`hub_spoke` focuses on:

- `features`
- `networking`
- `peering`
- optional `routing`
- `security`
- `nat_gateway`
- `bastion`
- optional `private_dns`
- optional `compute`
- optional `load_balancer`

For NAT naming, the Azure hub-and-spoke pattern also accepts optional maps:

- `nat_gateway.names.<vnet_key>`
- `nat_gateway.public_ip_names.<vnet_key>`

When router-VM transit is used, the compute payload may also provide:

- `compute.instances.<name>.nic_nsg_name`

When `routing` is used for explicit transit, the Azure hub-and-spoke pattern also accepts:

- `routing.route_tables.<name>.subnet_refs`
- `routing.route_tables.<name>.routes[]`
- `routing.route_tables.<name>.routes[].next_hop_vm_ref`

Example:

```yaml
routing:
  enabled: true
  route_tables:
    rt-app-backend:
      subnet_refs:
        - app.backend
      routes:
        - name: to-data-via-router
          address_prefix: 10.30.0.0/16
          next_hop_type: VirtualAppliance
          next_hop_vm_ref: hubrouter
```

`private_endpoint` extends that with:

- `storage`
- `private_endpoints`
- optional `compute_storage_mounts`

For private DNS, a more explicit contract is:

- `private_dns.zones[].name`
- `private_dns.zones[].link_to_vnets`

Example:

```yaml
private_dns:
  enabled: true
  zones:
    - name: privatelink.file.core.windows.net
      link_to_vnets:
        - app
```

If the new per-zone structure is not used, the current Azure hub-and-spoke pattern falls back to the older shared-link behavior for backward compatibility.

For routed private endpoint consumption scenarios, the Azure private endpoint pattern also accepts:

- `compute_storage_mounts.enabled`
- `compute_storage_mounts.name`
- `compute_storage_mounts.subnet_ref`
- `compute_storage_mounts.mount_azure_files.enabled`
- `compute_storage_mounts.mount_azure_files.share_name`
- `compute_storage_mounts.mount_azure_files.mount_path`

Example:

```yaml
compute_storage_mounts:
  enabled: true
  name: vm-fk-app-pe-01
  subnet_ref: app.backend
  size: Standard_B2s
  private_ip_address_allocation: Static
  private_ip_address: 10.20.2.4
  mount_azure_files:
    enabled: true
    share_name: shared
    mount_path: /mnt/azurefiles
```

Why this sits outside generic `compute.instances`:

- the VM depends on Storage Account outputs
- cloud-init must be rendered after the Storage Account and file share exist
- this keeps the shared `hub_spoke` pattern storage-agnostic while still allowing a storage-aware consumer VM in the private endpoint pattern

Operational note for local applies:

- the example wrapper may also accept a `provisioner_public_ip` input
- this is not architecture intent and therefore does not live in YAML
- it exists only to allow the local OpenTofu runner to create Azure Files data-plane resources while the Storage Account remains locked down by network rules

`firewall_transit` focuses on:

- `networking`
- `peering`
- `firewall`
- `routing`
- `compute`

`postgresql_private_access` focuses on:

- `architecture.private_access`
- `architecture.network`
- `workload.client`
- `data.postgresql`

For PostgreSQL delegated-subnet private access, the current contract is:

- `architecture.private_access.mode`
- `architecture.network.vnet.name`
- `architecture.network.vnet.cidr`
- `architecture.network.client_subnet.name`
- `architecture.network.client_subnet.cidr`
- `architecture.network.bastion_subnet.cidr`
- `architecture.network.delegated_subnet.name`
- `architecture.network.delegated_subnet.cidr`
- `workload.client.name`
- `workload.client.shape`
- `workload.client.admin_username`
- `workload.client.ssh_authorized_keys`
- `data.postgresql.server.name`
- `data.postgresql.server.private_dns_zone_name`
- `data.postgresql.server.version`
- `data.postgresql.server.sku`
- `data.postgresql.server.storage_mb`
- `data.postgresql.server.admin_login`
- `data.postgresql.server.admin_password`
- `data.postgresql.database.name`

Example:

```yaml
architecture:
  private_access:
    mode: delegated_subnet
  network:
    vnet:
      name: vnet-fk-azure-pg-private-access-dev
      cidr: 10.130.0.0/16
    client_subnet:
      name: snet-fk-pg-client
      cidr: 10.130.10.0/24
    bastion_subnet:
      cidr: 10.130.30.0/26
    delegated_subnet:
      name: snet-fk-pg-flexible
      cidr: 10.130.20.0/24

workload:
  client:
    name: vm-fk-pg-client
    shape: Standard_B1s
    admin_username: azureuser
    ssh_authorized_keys:
      - ssh-rsa REPLACE_WITH_PUBLIC_KEY_ONLY

data:
  postgresql:
    server:
      name: fk-pg-private-dev
      private_dns_zone_name: fk-azure-pg-private-access-dev.postgres.database.azure.com
      version: "16"
      sku: GP_Standard_D2s_v3
      storage_mb: 32768
      admin_login: pgadmin
      admin_password: REPLACE_WITH_STRONG_PASSWORD
    database:
      name: foggydb
```

The first public Azure database pattern supports only PostgreSQL Flexible Server with delegated-subnet private access. `data.postgresql.entra`, `data.postgresql.cmk`, and `data.postgresql.diagnostics` are reserved for a later secure variant.

`sql_private_access` focuses on:

- `architecture.private_access`
- `architecture.network`
- `workload.client`
- `data.sql`

For Azure SQL Private Endpoint access, the current contract is:

- `architecture.private_access.mode`
- `architecture.network.vnet.name`
- `architecture.network.vnet.cidr`
- `architecture.network.client_subnet.name`
- `architecture.network.client_subnet.cidr`
- `architecture.network.bastion_subnet.cidr`
- `architecture.network.private_endpoint_subnet.name`
- `architecture.network.private_endpoint_subnet.cidr`
- `workload.client.name`
- `workload.client.shape`
- `workload.client.admin_username`
- `workload.client.ssh_authorized_keys`
- `data.sql.server.name`
- `data.sql.server.private_dns_zone_name`
- `data.sql.server.version`
- `data.sql.server.admin_login`
- `data.sql.server.admin_password`
- `data.sql.database.name`
- `data.sql.database.sku_name`
- `data.sql.database.max_size_gb`

Example:

```yaml
architecture:
  private_access:
    mode: private_endpoint
  network:
    vnet:
      name: vnet-fk-azure-sql-private-access-dev
      cidr: 10.140.0.0/16
    client_subnet:
      name: snet-fk-sql-client
      cidr: 10.140.10.0/24
    private_endpoint_subnet:
      name: snet-fk-sql-private-endpoint
      cidr: 10.140.20.0/24
    bastion_subnet:
      cidr: 10.140.30.0/26

workload:
  client:
    name: vm-fk-sql-client
    shape: Standard_B1s
    admin_username: azureuser
    ssh_authorized_keys:
      - ssh-rsa REPLACE_WITH_PUBLIC_KEY_ONLY

data:
  sql:
    server:
      name: fk-sql-private-dev
      private_dns_zone_name: privatelink.database.windows.net
      version: "12.0"
      admin_login: sqladmin
      admin_password: REPLACE_WITH_STRONG_PASSWORD
    database:
      name: foggydb
      sku_name: S0
      max_size_gb: 2
```

The Azure SQL pattern supports only Private Endpoint mode. `data.sql.entra`, `data.sql.cmk`, and `data.sql.diagnostics` are reserved for a later secure variant.

`mysql_private_access` focuses on:

- `architecture.private_access`
- `architecture.network`
- `workload.client`
- `data.mysql`

For MySQL delegated-subnet private access, the current contract is:

- `architecture.private_access.mode`
- `architecture.network.vnet.name`
- `architecture.network.vnet.cidr`
- `architecture.network.client_subnet.name`
- `architecture.network.client_subnet.cidr`
- `architecture.network.bastion_subnet.cidr`
- `architecture.network.delegated_subnet.name`
- `architecture.network.delegated_subnet.cidr`
- `workload.client.name`
- `workload.client.shape`
- `workload.client.admin_username`
- `workload.client.ssh_authorized_keys`
- `data.mysql.server.name`
- `data.mysql.server.private_dns_zone_name`
- `data.mysql.server.version`
- `data.mysql.server.sku`
- `data.mysql.server.storage`
- `data.mysql.server.storage.size_gb`
- `data.mysql.server.admin_login`
- `data.mysql.server.admin_password`
- `data.mysql.database.name`
- optional `data.mysql.database.charset`
- optional `data.mysql.database.collation`

Example:

```yaml
architecture:
  private_access:
    mode: delegated_subnet
  network:
    vnet:
      name: vnet-fk-azure-mysql-private-access-dev
      cidr: 10.150.0.0/16
    client_subnet:
      name: snet-fk-mysql-client
      cidr: 10.150.10.0/24
    bastion_subnet:
      cidr: 10.150.30.0/26
    delegated_subnet:
      name: snet-fk-mysql-flexible
      cidr: 10.150.20.0/24

workload:
  client:
    name: vm-fk-mysql-client
    shape: Standard_B1s
    admin_username: azureuser
    ssh_authorized_keys:
      - ssh-rsa REPLACE_WITH_PUBLIC_KEY_ONLY

data:
  mysql:
    server:
      name: fk-mysql-private-dev
      private_dns_zone_name: fk-azure-mysql-private-access-dev.mysql.database.azure.com
      version: "8.0.21"
      sku: GP_Standard_D2ds_v4
      storage:
        size_gb: 32
      admin_login: mysqladmin
      admin_password: REPLACE_WITH_STRONG_PASSWORD
    database:
      name: foggydb
```

The MySQL pattern supports only Azure Database for MySQL Flexible Server with delegated-subnet private access. For this mode, the Private DNS Zone must end with `mysql.database.azure.com`. `data.mysql.entra`, `data.mysql.cmk`, and `data.mysql.diagnostics` are reserved for a later secure variant.

---

`cosmosdb_private_access` focuses on:

- `architecture.private_access`
- `architecture.network`
- `workload.client`
- `data.cosmosdb`

For Cosmos DB SQL API Private Endpoint access, the current contract is:

- `architecture.private_access.mode`
- `architecture.network.vnet.name`
- `architecture.network.vnet.cidr`
- `architecture.network.client_subnet.name`
- `architecture.network.client_subnet.cidr`
- `architecture.network.bastion_subnet.cidr`
- `architecture.network.private_endpoint_subnet.name`
- `architecture.network.private_endpoint_subnet.cidr`
- `workload.client.name`
- `workload.client.shape`
- `workload.client.admin_username`
- `workload.client.ssh_authorized_keys`
- `data.cosmosdb.account.name`
- `data.cosmosdb.account.private_dns_zone_name`
- `data.cosmosdb.account.kind`
- `data.cosmosdb.sql_database.name`
- optional `data.cosmosdb.sql_database.throughput`
- `data.cosmosdb.sql_container.name`
- `data.cosmosdb.sql_container.partition_key_paths`
- optional `data.cosmosdb.sql_container.partition_key_version`

Example:

```yaml
architecture:
  private_access:
    mode: private_endpoint
  network:
    vnet:
      name: vnet-fk-azure-cosmosdb-private-access-dev
      cidr: 10.160.0.0/16
    client_subnet:
      name: snet-fk-cosmosdb-client
      cidr: 10.160.10.0/24
    private_endpoint_subnet:
      name: snet-fk-cosmosdb-private-endpoint
      cidr: 10.160.20.0/24
    bastion_subnet:
      cidr: 10.160.30.0/26

workload:
  client:
    name: vm-fk-cosmosdb-client
    shape: Standard_B1s
    admin_username: azureuser
    ssh_authorized_keys:
      - ssh-rsa REPLACE_WITH_PUBLIC_KEY_ONLY

data:
  cosmosdb:
    account:
      name: fk-cosmosdb-private-dev
      private_dns_zone_name: privatelink.documents.azure.com
      kind: GlobalDocumentDB
    sql_database:
      name: foggydb
      throughput: 400
    sql_container:
      name: items
      partition_key_paths:
        - /partitionKey
      partition_key_version: 2
```

The Cosmos DB pattern supports only the SQL API with Private Endpoint access. The Private Endpoint subresource is `Sql` and the Private DNS Zone is `privatelink.documents.azure.com`. Cosmos DB has no Entra administrator concept; a later secure variant should use `local_authentication_enabled = false` with data-plane RBAC role assignments and `key_vault_key_id` / `default_identity_type` for customer-managed keys. `data.cosmosdb.identity`, `data.cosmosdb.cmk`, `data.cosmosdb.diagnostics`, and `data.cosmosdb.rbac` are reserved for a later secure variant.

---

## ☁️ OCI Payload Shape

Common OCI payload sections may include:

- `landing_zone`
- `cloud`
- `architecture`
- `networking`
- `connectivity`
- `compute`
- `load_balancer`

### Example Usage by Pattern

`drg_cross_region` focuses on:

- split-region `networking`
- `connectivity.drg`
- explicit home and peer route table intent

`lpg_local_peering` focuses on:

- multi-VCN `networking`
- `connectivity.lpg`
- private `compute`
- private `load_balancer`

---

## 🔒 Public Contract Boundary

This public repository documents the payload contract for the currently exposed Azure and OCI reference patterns.

More advanced multicloud payload contracts may be maintained separately in the private:

- `foggykitchen-landing-zone-blueprint`

repository when they are treated as premium blueprint content.

---

## ⚠️ Contract Philosophy

The payload contract should evolve carefully.

Good evolution:

- add a new section for a clearly separate capability
- add a new logical reference type
- add a new pattern-specific subtree

Bad evolution:

- exposing raw module source strings
- turning payloads into unstructured provider argument bags
- forcing unrelated patterns into a single schema for the sake of uniformity

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
