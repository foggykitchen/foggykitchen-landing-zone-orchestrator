# Changelog

## v2.2.0 — 2026-11-21

### Added

- OCI BaseDB private-access pattern and basic example: private VM DB system, private validation host, Bastion Service, NSGs, NAT/SGW, plan-only tests and payload documentation. Live validated in Frankfurt: Managed SSH and TCP/1521 passed; all 26 resources were destroyed after validation.

### Validation and known limitations

- Includes the architecture diagram, 11 OCI console screenshots and documented TCP validation.
- Fixed Bastion wait and first-boot package installation required retries during live validation; these limitations are documented. SQL authentication and manual port forwarding were not tested.
- See [v2.2.0 release notes](docs/release-v2.2.0.md) and [validation report](docs/pr-basedb-private-access.md).

## v2.1.0 — 2026-11-13

Minor release; landing-zone payload keys are unchanged.

| Module | Previous references | Release pin |
| --- | --- | --- |
| `terraform-az-fk-acr` | `v0.2.0` | `v0.2.2` |
| `terraform-az-fk-bastion` | `main`, `v1.0.0` | `v1.0.1` |
| `terraform-az-fk-compute` | `v0.3.5` | `v0.4.1` |
| `terraform-az-fk-firewall` | `v0.2.0` | `v0.2.1` |
| `terraform-az-fk-loadbalancer` | `v1.2.0` | `v1.2.1` |
| `terraform-az-fk-natgw` | `main`, `v1.1.0` | `v1.1.1` |
| `terraform-az-fk-nsg` | `main`, `v1.0.0` | `v1.0.1` |
| `terraform-az-fk-private-dns` | `main`, `v1.0.0` | `v1.0.1` |
| `terraform-az-fk-private-endpoint` | `main`, `v1.0.0` | `v1.0.1` |
| `terraform-az-fk-public-ip` | `main`, `v1.0.0` | `v1.0.1` |
| `terraform-az-fk-rbac` | `v0.1.2` | `v0.1.4` |
| `terraform-az-fk-routing` | `main`, `v0.4.2` | `v0.4.3` |
| `terraform-az-fk-storage` | `main` | `v1.1.0` |
| `terraform-az-fk-vnet` | `main` | `v0.1.2` |
| `terraform-az-fk-vnet-peering` | `main` | `v0.1.1` |

- Retain OCI Function v2.0.1 from main; other OCI module pins stay unchanged.
- Require OpenTofu >= 1.11.0 for Azure and bound AzureRM below v5, preserving higher minimum versions.
- Extend module-reference CI to Azure, add scheduled/manual latest-tag checks and validate all example roots with OpenTofu 1.11.6.
- Validation: 25 init, 25 validate and 12 tested roots passed; reference checks returned 0 errors. No apply/destroy. See [release notes](docs/release-v2.1.0.md) and [validation](docs/validation-v2.1.0.md).
- Replace 21 floating Azure pins with tags and add three plan-only mocked Azure tests.

## v2.0.0 — 2026-11-13

- **BREAKING:** OCI patterns and examples require `oracle/oci >= 9.12.1, < 10.0.0` and OpenTofu `>= 1.11.0`; OCI 6 is no longer supported.
- Pin all 19 composed OCI modules to compatible releases, including Compute v0.3.0, DNS Steering v0.2.0, ADB v2.0.0 and Functions v2.0.0. Replace floating OCI module references with release tags.
- Preserve ADB and Functions inputs and sensitive wallet outputs; expose only the ADB private endpoint IP in the diagnostic command.
- Add plan-only mocked tests for all nine OCI examples, module-reference CI, and payload compatibility metadata.
- Migration: run `tofu init -upgrade` in each OCI root and review `tofu plan` before applying.

See [migration details and validation results](docs/oci-provider-9-migration.md). BaseDB work is excluded from this release change.
