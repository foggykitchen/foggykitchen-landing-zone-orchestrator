# OCI provider 9 migration — v2.0.0

## Breaking compatibility change

Orchestrator **v2.0.0** requires `oracle/oci >= 9.12.1, < 10.0.0` and OpenTofu `>= 1.11.0` for every OCI example and shared pattern. OCI 6 is no longer supported by these compositions. The change is scoped to OCI; Azure constraints and module references are unchanged.

From each existing OCI root directory, using its normal backend and inputs:

```sh
tofu init -upgrade
tofu validate
tofu plan
```

Review the resulting dependency lock file and plan before applying. Update all composed OCI modules together. These checks do not establish replacement-free migration of existing infrastructure. Keep prior orchestrator/module versions for stacks that must remain on OCI 6.

## Module release review

All 19 direct OCI dependencies are pinned to released tags. Changelogs (or Load Balancer README compatibility notes), input/output changes and downloaded root Terraform source were reviewed against the selected tags.

| Module | Tag | Consumer impact |
| --- | --- | --- |
| adb | [v2.0.0](https://github.com/foggykitchen/terraform-oci-fk-adb/blob/v2.0.0/CHANGELOG.md) | Inputs unchanged from v1.4. The complete adb_database output is now sensitive; existing wallet/ADB exports remain sensitive. The validation command explicitly exposes only the non-secret private endpoint IP. SINGLE wallet generation is preserved upstream. |
| api-gateway | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-api-gateway/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| compute | [v0.3.0](https://github.com/foggykitchen/terraform-oci-fk-compute/blob/v0.3.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| devops | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-devops/blob/v0.2.0/CHANGELOG.md) | Adds trigger_urls since v0.1.0; existing outputs remain available. |
| devops-pipeline | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-devops-pipeline/blob/v0.2.0/CHANGELOG.md) | Adds further dependent-stage outputs and trigger outputs since the older pins; existing stage wiring remains compatible. |
| dns-steering | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-dns-steering/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| drg | [v0.5.0](https://github.com/foggykitchen/terraform-oci-fk-drg/blob/v0.5.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| event | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-event/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| function | [v2.0.0](https://github.com/foggykitchen/terraform-oci-fk-function/blob/v2.0.0/CHANGELOG.md) | Inputs and outputs unchanged from v0.2.0. Provider/runtime requirements are breaking. |
| loadbalancer | [v2.0.0](https://github.com/foggykitchen/terraform-oci-fk-loadbalancer/blob/v2.0.0/README.md) | Drops OCI 6 support; input/output names and resource addresses are preserved. |
| lpg | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-lpg/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| nsg | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-nsg/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| objectstorage | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-objectstorage/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| ocir | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-ocir/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| oke | [v0.4.0](https://github.com/foggykitchen/terraform-oci-fk-oke/blob/v0.4.0/CHANGELOG.md) | Adds optional kms_key_id and selects node images by Kubernetes version/architecture since v0.1.0. Existing pattern inputs remain compatible. |
| policy | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-policy/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| sch | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-sch/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| streaming | [v0.2.0](https://github.com/foggykitchen/terraform-oci-fk-streaming/blob/v0.2.0/CHANGELOG.md) | OCI 9 compatibility release; existing composition inputs and outputs are retained. |
| vcn | [v0.3.0](https://github.com/foggykitchen/terraform-oci-fk-vcn/blob/v0.3.0/CHANGELOG.md) | Adds optional DHCP inputs and outputs since v0.1.0; existing subnet and routing inputs remain compatible. |

The ADB OCPU/Free Tier, endpoint, storage and autoscaling choices are unchanged. No input rename is required for ADB v1.4 → v2.0.0 or Functions v0.2.0 → v2.0.0. Full ADB objects and wallet material remain sensitive at the pattern and example boundaries.

`compatibility` in `landing-zone.yaml` is informational metadata. Executable provider constraints and module sources live in Terraform files. Application source branches are independent of module release pins.

## Validation

Verified on 2026-11-13 with OpenTofu 1.11.6, OCI provider 9.13.0, darwin_arm64. Every example below passed initialization, validation, and a plan-only test with output assertions. Tests mock providers, use synthetic inputs and never execute apply.

| Example under examples/oci | init | validate | mocked plan |
| --- | --- | --- | --- |
| `adb/private_access/basic` | PASS | PASS | PASS |
| `devops/build_and_deploy_oke/basic` | PASS | PASS | PASS |
| `devops/build_only/basic` | PASS | PASS | PASS |
| `functions/authenticated_serverless_api/basic` | PASS | PASS | PASS |
| `functions/bulk_ingestion_pipeline/basic` | PASS | PASS | PASS |
| `functions/event_driven_data_pipeline/basic` | PASS | PASS | PASS |
| `multiregion/compute_failover/basic` | PASS | PASS | PASS |
| `networking/drg_cross_region/basic` | PASS | PASS | PASS |
| `networking/lpg_local_peering/basic` | PASS | PASS | PASS |

To reproduce, run from each example directory:

```sh
tofu init -backend=false -input=false -upgrade
tofu validate
tofu test
```

Every test explicitly uses `command = plan`. Mocked plans verify module composition and selected output contracts; they do not verify real OCI data-source results, IAM, service availability, runtime connectivity, function builds, or existing-state upgrades. No live plan, apply, destroy, pipeline execution or function invocation was performed. The Functions module emits a non-blocking deprecation warning for its `image` field.

Formatting (`tofu fmt -recursive -check patterns/oci examples/oci`), whitespace checks and positive/negative module reference checks pass. CI runs `python3 scripts/check-module-refs.py` to reject floating OCI `main`/`master` module references. Downloaded root `.tf` files and changelogs for all 19 modules match the reviewed release tags byte-for-byte.

## Release and follow-up

Publish orchestrator **v2.0.0** from the merged migration commit with the breaking-change notice and `tofu init -upgrade` migration instruction. This document prepares the release; it does not indicate that a tag has already been published.

`examples/oci/database/basedb/private_access/basic` (BaseDB plan step 1) is explicitly excluded. It can proceed separately after this PR is merged.
