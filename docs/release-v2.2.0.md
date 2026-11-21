# v2.2.0 — OCI BaseDB private access

Adds `patterns/oci/basedb_private_access` and `examples/oci/database/basedb/private_access/basic`: a private Oracle Base Database VM system, Oracle Linux 9 validation host and OCI Bastion Service in an existing compartment. Both subnets are private; traffic uses NSGs, NAT and Service Gateway without an Internet Gateway.

## Compatibility and module pins

Requires OpenTofu >= 1.11.0 and OCI provider >= 9.12.1, < 10.0.0. This is an additive minor release; existing payloads remain unchanged. Users upgrading from OCI provider 6 must follow the [v2.0.0 migration guide](oci-provider-9-migration.md), run `tofu init -upgrade` and review their plan.

| Module | Tag |
| --- | --- |
| BaseDB | v0.1.0 |
| Bastion Service | v0.2.0 |
| Compute | v0.3.0 |
| NSG | v0.2.0 |
| VCN | v0.3.0 |

## Validation

- Offline regression: 26 example roots passed fmt/init/validate, with 16 plan-only mocked runs across 13 test suites; module-reference checks covered 49 module sources.
- Live deployment on 2026-11-21 in eu-frankfurt-1: VM.BaseDB.x86, 4 ECPUs, 256 GB, Standard Edition, LICENSE_INCLUDED, database version 23.26.4.0.0.
- BaseDB creation: 42m10s. Managed SSH and client-to-database TCP/1521 checks passed.
- Cleanup: 26 resources destroyed; zero managed resources remaining in state. The existing compartment was retained.
- Documentation includes an architecture diagram, 11 OCI console screenshots and textual TCP test results. See the [example](../examples/oci/database/basedb/private_access/basic/README.md) and [validation report](pr-basedb-private-access.md).

## Known limitations

The initial Managed SSH request failed because the Bastion plugin was not ready after the fixed 600-second delay. Retrying once the plugin was RUNNING succeeded. Initial package installation could not reach yum.oracle.com; retrying over SSH succeeded without network changes. Fresh deployments may require these retries. SQL authentication and manual port forwarding were not tested.

BaseDB is a paid service with no Free Tier. Passwords and generated SSH private keys are stored in state: use an encrypted, access-controlled backend. Data Guard and MCP catalog reindexing are separate follow-up work.
