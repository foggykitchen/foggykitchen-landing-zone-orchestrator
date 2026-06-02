# OCI ADB Private Access - Basic Example

This example composes a **private Autonomous Database Serverless endpoint** with a **small public validation host** in the same VCN.

It is inspired by:

- `terraform-oci-fk-adb/training/lesson3_adb_with_private_endpoint`

but reshaped into a reusable `foggykitchen-landing-zone-orchestrator` pattern and payload.

## What This Example Deploys

- one VCN
- one public client subnet
- one private ADB subnet
- one NSG attached to the ADB private endpoint
- one Autonomous Database Serverless deployment with a private endpoint
- one lightweight public compute instance used to validate private SQL*Net reachability

## Pattern

- [`patterns/oci/adb_private_access`](../../../../../../patterns/oci/adb_private_access/README.md)

## Files

- [landing-zone.yaml](landing-zone.yaml)
- [main.tf](main.tf)
- [providers.tf](providers.tf)
- [variables.tf](variables.tf)
- [outputs.tf](outputs.tf)

## Deploy

```bash
tofu init
tofu plan
tofu apply
```

## Validation Flow

After apply:

1. Connect to the validation host:

```bash
ssh opc@<validation-host-public-ip>
```

2. Validate private SQL*Net reachability to the ADB private endpoint:

```bash
nc -vz <adb-private-endpoint-ip> 1522
```

Expected result:

- TCP port `1522` is reachable from the validation host
- the ADB private endpoint remains inaccessible directly from the public internet

## Destroy

```bash
tofu destroy
```

## Notes

- This public example validates **private network access**, not full schema bootstrap or data loading.
- The validation host can be customized with `workload.client.cloud_init_override`.
- `adb_wallet` is exposed as a **sensitive output** for downstream client tooling if needed.

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
