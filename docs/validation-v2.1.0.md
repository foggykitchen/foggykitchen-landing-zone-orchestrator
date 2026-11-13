# Local validation for v2.1.0

Date: 2026-11-13. OpenTofu 1.11.6, macOS arm64. No apply/destroy.

## Results

| Check | Passed | Failed |
| --- | ---: | ---: |
| `fmt` example roots | 25 | 0 |
| `init` example roots | 25 | 0 |
| `validate` example roots | 25 | 0 |
| `test` example roots | 12 | 0 |

`python3 scripts/check-module-refs.py`: 0 errors.

`python3 scripts/check-module-refs.py --latest`: 47 modules, 0 errors (fresh `git ls-remote --tags --refs`).

`python3 scripts/test_check_module_refs.py`: 4 tests passed.

`git diff --check`: passed. Source-tree floating main/master module-reference scan: 0 matches, excluding downloaded `.terraform` modules and Git metadata. All landing-zone.yaml files are byte-for-byte unchanged from the base commit.

## Commands

```sh
python3 scripts/check-module-refs.py
python3 scripts/check-module-refs.py --latest
python3 scripts/test_check_module_refs.py
python3 scripts/validate-examples.py
```

The runner executes `tofu fmt -check`, `tofu init -backend=false -input=false`, `tofu validate` and `tofu test` where test files exist. Every test run explicitly uses `command = plan` and mocks cloud providers. No backend initialization or cloud deployment occurs.

The initial full sweep found fixture errors in the new PostgreSQL test; AKS was initialized before its test was added. After correcting fixtures, targeted AKS and PostgreSQL test reruns each passed (1 passed, 0 failed); the table below combines the full sweep with those final reruns.

AKS test scope: network/access composition with the upstream cluster module outputs overridden. OpenTofu 1.11.6 cannot populate its absent computed `kubelet_identity` block. Full cluster configuration remains covered by init/validate. Subnet mock IDs use AzureBastionSubnet to satisfy provider validation; CIDR separation assertions use the actual payload. See [OpenTofu 1.11 test documentation](https://opentofu.org/docs/v1.11/cli/commands/test/).

## Selected providers

| Provider | Versions |
| --- | --- |
| `registry.opentofu.org/azure/azapi` | 2.13.0 |
| `registry.opentofu.org/hashicorp/archive` | 2.8.1 |
| `registry.opentofu.org/hashicorp/azuread` | 3.10.0 |
| `registry.opentofu.org/hashicorp/azurerm` | 4.81.0 |
| `registry.opentofu.org/hashicorp/local` | 2.9.1 |
| `registry.opentofu.org/hashicorp/null` | 3.3.2 |
| `registry.opentofu.org/hashicorp/random` | 3.9.1 |
| `registry.opentofu.org/hashicorp/time` | 0.14.2 |
| `registry.opentofu.org/hashicorp/tls` | 4.4.2 |
| `registry.opentofu.org/microsoft/azuredevops` | 1.16.0 |
| `registry.opentofu.org/oracle/oci` | 9.13.0 |

## Example results

| Example | fmt | init | validate | test |
| --- | --- | --- | --- | --- |
| `examples/azure/aks/basic` | PASS | PASS | PASS | PASS |
| `examples/azure/aks/private_acr` | PASS | PASS | PASS | No tests |
| `examples/azure/database/cosmosdb/private_access/private_endpoint` | PASS | PASS | PASS | No tests |
| `examples/azure/database/mysql/private_access/delegated_subnet` | PASS | PASS | PASS | No tests |
| `examples/azure/database/mysql/private_access/private_endpoint` | PASS | PASS | PASS | No tests |
| `examples/azure/database/postgresql/private_access/delegated_subnet` | PASS | PASS | PASS | PASS |
| `examples/azure/database/postgresql/private_access/private_endpoint` | PASS | PASS | PASS | No tests |
| `examples/azure/database/sql/private_access/private_endpoint` | PASS | PASS | PASS | No tests |
| `examples/azure/devops/build_and_deploy_aks/basic` | PASS | PASS | PASS | No tests |
| `examples/azure/functions/bulk_ingestion_pipeline/basic` | PASS | PASS | PASS | No tests |
| `examples/azure/functions/event_driven_data_pipeline/basic` | PASS | PASS | PASS | No tests |
| `examples/azure/multiregion/compute_failover/basic` | PASS | PASS | PASS | No tests |
| `examples/azure/networking/firewall_transit/basic` | PASS | PASS | PASS | No tests |
| `examples/azure/networking/hub_spoke/basic` | PASS | PASS | PASS | PASS |
| `examples/azure/networking/hub_spoke/routing` | PASS | PASS | PASS | No tests |
| `examples/azure/networking/private_endpoint/storage_private_link` | PASS | PASS | PASS | No tests |
| `examples/oci/adb/private_access/basic` | PASS | PASS | PASS | PASS |
| `examples/oci/devops/build_and_deploy_oke/basic` | PASS | PASS | PASS | PASS |
| `examples/oci/devops/build_only/basic` | PASS | PASS | PASS | PASS |
| `examples/oci/functions/authenticated_serverless_api/basic` | PASS | PASS | PASS | PASS |
| `examples/oci/functions/bulk_ingestion_pipeline/basic` | PASS | PASS | PASS | PASS |
| `examples/oci/functions/event_driven_data_pipeline/basic` | PASS | PASS | PASS | PASS |
| `examples/oci/multiregion/compute_failover/basic` | PASS | PASS | PASS | PASS |
| `examples/oci/networking/drg_cross_region/basic` | PASS | PASS | PASS | PASS |
| `examples/oci/networking/lpg_local_peering/basic` | PASS | PASS | PASS | PASS |

## Publication gate

Local checks are complete. MCP latestVersion, stale=false and aggregate validationReport.count=0 must be verified after approved push, PR review/merge, an annotated tag on main, GitHub release and reindexing. They are not claimed by this local report.
