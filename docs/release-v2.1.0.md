# v2.1.0

Minor release: refresh module pins and validation policy without changing the landing-zone YAML payload contract. Base main commit: `f61e2ca`.

## Module updates

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

- Retain the main-branch OCI Function update from v2.0.0 to v2.0.1, including explicit local/null provider constraints. Other OCI pins are unchanged and verified current.
- All 19 requested Azure target tags remain the latest stable semver tags; no newer replacement was needed.
- Replace all 21 floating Azure references in hub_spoke, firewall_transit and private_endpoint. The ten affected module main commits equal the selected tag commits; pinning itself does not change their source code.

## Compatibility review

- Compute v0.3.5 → v0.4.1 adds nullable `app_gateway_attachment` with default `null`; existing inputs and Load Balancer attachments are preserved. The new multi-NIC precondition is inactive for existing null attachments. Reviewed `inputs.tf`, `main.tf`, and release notes for v0.4.0/v0.4.1.
- Application Gateway v0.1.2 → v0.2.1 adds optional Private Link configuration and an optional field on the private frontend. Existing public listener inputs remain supported. Reviewed the input/resource diff and v0.2.0/v0.2.1 release notes; no payload keys need migration.
- Storage v1.1.0 adds optional queues. VNG v0.2.2 fixes validation of the nullable generation input. Remaining updates primarily bound AzureRM below v5 or refresh documentation.
- Reviewed available release notes for every upgrade. GitHub release notes are absent for the intermediate ACR v0.2.1, RBAC v0.1.3, VNG v0.2.3 and Public IP v1.0.1 tags; reviewed their committed changes instead. These introduce no required input changes.

## Runtime and CI

- Azure and multicloud example roots and patterns require OpenTofu `>= 1.11.0`.
- AzureRM roots use a 4.x lower bound and `< 5.0.0`; preserve higher existing lower bounds, including MySQL `>= 4.26.0` and existing `>= 4.81.0` requirements.
- Declared helper providers retain explicit constraints; open TLS constraints are bounded below v5.
- Module-reference policy covers both OCI and Azure. `--latest` verifies stable semver tags using GitHub, in a separate weekly/manual CI job so upstream releases do not break pull-request checks.
- A dynamically discovered CI matrix checks every example with OpenTofu 1.11.6, plugin caching, backend-disabled init, validate, and explicit plan-only tests where present. No cloud credentials are configured.
- No apply or destroy was executed. No deployment or live Azure/OCI behavior is claimed by mocked tests.

## Validation

Passed: 25 init, 25 validate, 12 tested example roots (0 failures after fixture corrections). Selected OCI 9.13.0 and AzureRM 4.81.0.

See [local validation report](validation-v2.1.0.md) for exact counts, provider selections and commands. Publication and MCP acceptance remain pending approval, merge, annotated tagging, GitHub release and reindexing.

Three new mocked Azure tests cover hub-spoke/basic, AKS/basic and PostgreSQL delegated private access. Other Azure examples currently receive init/validate coverage only.

AKS mock-test limitation: the upstream cluster outputs are overridden because OpenTofu 1.11.6 cannot populate its absent computed kubelet_identity block. The test checks LZ network/access composition; full cluster configuration is covered by init/validate.
