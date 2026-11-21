# Add OCI BaseDB private access with Bastion Service

## Problem and behavior

The orchestrator has an ADB example but no Base Database VM-system composition. This change adds `patterns/oci/basedb_private_access` and `examples/oci/database/basedb/private_access/basic` with a single PRIMARY BaseDB, a private OL9 validation host and OCI Bastion Service. Both workloads remain private; no Internet Gateway is created.

The example uses VM.BaseDB.x86, 4 ECPUs, 256 GB, Standard Edition and LICENSE_INCLUDED. Database version is a required input; 23.26.4.0.0 is the documented upstream example, subject to regional availability. BaseDB has no Free Tier. A user-approved live deployment and host-to-BaseDB TCP/1521 check succeeded on 2026-11-21 in eu-frankfurt-1; see the example README for details.

## Design decisions

- Use an existing compartment. No compartment or IAM resources are created.
- Use Bastion Service instead of a public jump host. Create one optional managed SSH session to the client; document separate manual forwarding to DB TCP/1521.
- Map both BaseDB provider slots explicitly: `oci = oci`, `oci.target = oci`. Database and VNIC discovery use the same workload region as creation.
- Pin BaseDB v0.1.0, Bastion Service v0.2.0, Compute v0.3.0, NSG v0.2.0 and VCN v0.3.0. BaseDB v0.1.0 sets LVM internally for ECPU and exposes no storage-management input. Upstream modules are unchanged.
- Two private subnets exclude the default security list. DB security list is empty. Client security list permits only service-managed Bastion endpoint egress TCP/22 to the client subnet and TCP/1521 to the database subnet. This small exception is necessary because the endpoint cannot inherit the client's VNIC NSG; see [Oracle Bastion network setup](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengsettingupbastion.htm). Workload ingress remains in NSGs, without public CIDRs. These subnet-level egress grants are additive to the client NSG and affect all VNICs in the shared client subnet; isolating the endpoint policy would require a third subnet.
- Database HTTPS egress is limited to the regional OSN service CIDR via SGW. Client HTTPS egress can use NAT. PMTUD is limited to the VCN CIDR, preserving the prohibition on public ingress.
- Enable the Bastion agent plugin and wait 600 seconds after client creation. The wait is not a health probe; live readiness must be confirmed separately.
- Keep the password and optional generated public key outside YAML rendering via dedicated pattern inputs. YAML retains the requested runtime placeholders. This preserves sensitive password handling and plan-known topology when TLS generates the SSH key during apply. Password and operator CIDR are runtime environment inputs, absent from the tfvars example.
- Document the new `database/<service>` convention. Existing `examples/oci/adb` remains in place. Document the v2.2.0 release in the changelog and release notes.

## Validation

Verified on 2026-11-18 with OpenTofu **1.11.6** on darwin_arm64. BaseDB resolved OCI **9.13.0**, TLS **4.4.2**, and time **0.14.2**.

| Command | Result |
| --- | --- |
| `python3 scripts/check-module-refs.py` | PASS — 49 modules, no floating refs |
| `python3 scripts/check-module-refs.py --latest` | PASS — 49 modules, 0 errors; all pins match current stable tags |
| `python3 scripts/validate-examples.py --example examples/oci/database/basedb/private_access/basic` | PASS — fmt, init, validate; 4/4 mocked plans |
| `python3 scripts/validate-examples.py` | PASS — all 26 roots; 13 test suites with 16/16 plan-only runs |
| `tofu fmt -check -recursive` | PASS |
| `git diff --check` | PASS |

The 13 roots without test suites received fmt/init/validate only; they were not given new plan coverage by this change. All checks use initialization without backend changes, configuration validation and explicitly plan-only tests. These offline checks do not access a live tenancy. The subsequent user-approved live plan, deployment, access test and cleanup are recorded below.

<details>
<summary>Per-example regression results</summary>

| Example | fmt | init | validate | Plan tests |
| --- | --- | --- | --- | --- |
| `examples/azure/aks/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/azure/aks/private_acr` | PASS | PASS | PASS | No test suite |
| `examples/azure/database/cosmosdb/private_access/private_endpoint` | PASS | PASS | PASS | No test suite |
| `examples/azure/database/mysql/private_access/delegated_subnet` | PASS | PASS | PASS | No test suite |
| `examples/azure/database/mysql/private_access/private_endpoint` | PASS | PASS | PASS | No test suite |
| `examples/azure/database/postgresql/private_access/delegated_subnet` | PASS | PASS | PASS | 1 PASS |
| `examples/azure/database/postgresql/private_access/private_endpoint` | PASS | PASS | PASS | No test suite |
| `examples/azure/database/sql/private_access/private_endpoint` | PASS | PASS | PASS | No test suite |
| `examples/azure/devops/build_and_deploy_aks/basic` | PASS | PASS | PASS | No test suite |
| `examples/azure/functions/bulk_ingestion_pipeline/basic` | PASS | PASS | PASS | No test suite |
| `examples/azure/functions/event_driven_data_pipeline/basic` | PASS | PASS | PASS | No test suite |
| `examples/azure/multiregion/compute_failover/basic` | PASS | PASS | PASS | No test suite |
| `examples/azure/networking/firewall_transit/basic` | PASS | PASS | PASS | No test suite |
| `examples/azure/networking/hub_spoke/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/azure/networking/hub_spoke/routing` | PASS | PASS | PASS | No test suite |
| `examples/azure/networking/private_endpoint/storage_private_link` | PASS | PASS | PASS | No test suite |
| `examples/oci/adb/private_access/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/oci/database/basedb/private_access/basic` | PASS | PASS | PASS | 4 PASS |
| `examples/oci/devops/build_and_deploy_oke/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/oci/devops/build_only/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/oci/functions/authenticated_serverless_api/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/oci/functions/bulk_ingestion_pipeline/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/oci/functions/event_driven_data_pipeline/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/oci/multiregion/compute_failover/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/oci/networking/drg_cross_region/basic` | PASS | PASS | PASS | 1 PASS |
| `examples/oci/networking/lpg_local_peering/basic` | PASS | PASS | PASS | 1 PASS |

</details>

Existing upstream deprecated-argument warnings remain non-blocking. Raw local logs are in the ignored `.validation/` directory; they are not committed. Test providers are mocked, so these results do not establish live service availability, plugin readiness or network connectivity.

The BaseDB test file has four runs: composition/output identifiers, rejection of operator `0.0.0.0/0`, TLS key fallback, and pattern network/security assertions. OCI, TLS and time providers are mocked. Target database/VNIC data reads that depend on new resources can remain unknown until apply; no runtime private-IP discovery or network connectivity is claimed from these tests.

## Live validation — 2026-11-21

- Initial live plan: 26 to add, 0 to change, 0 to destroy. BaseDB creation completed after 42m10s.
- First apply created the infrastructure but failed to create the Managed SSH session because the Bastion plugin was not RUNNING after the fixed 600-second wait.
- Once the plugin was RUNNING, a second plan/apply created only the missing session: 1 added, 0 changed, 0 destroyed.
- Managed SSH succeeded. Initial cloud-init package installation failed to reach yum.oracle.com; retrying `dnf install nmap-ncat bind-utils` succeeded without network-rule changes.
- `nc -vz -w 10 10.130.20.59 1521` from the private validation host succeeded. SQL authentication and manual forwarding have not been tested. User-approved cleanup succeeded on 2026-11-21: 26 resources destroyed, zero managed resources remaining in state, and BaseDB reported TERMINATED by OCI. Eleven OCI console screenshots are included in the example README; TCP validation is documented as text.
- Open reliability issues: the fixed delay is not a readiness check, and package installation needs retry handling. The current composition can need manual retries on first deployment.

## Remaining limitations and follow-up

- The live run validates eu-frankfurt-1 only; verify version availability, limits, capacity and IAM in each target tenancy/region.
- Replace or supplement the fixed Bastion readiness delay and add resilient first-boot package installation in follow-up work. The observed manual retries are documented in the example README.
- SQL authentication, manual forwarding and PMTUD behavior on external paths remain unverified. Use an encrypted backend and restrict state access outside this disposable lab.
- Same-region and cross-region Data Guard are future orchestrator steps, followed by blueprint work. They are excluded here and require their own edition/licensing/compatibility review.

See [v2.2.0 release notes](release-v2.2.0.md). MCP catalog reindexing is a separate follow-up and is not claimed by the GitHub release.
