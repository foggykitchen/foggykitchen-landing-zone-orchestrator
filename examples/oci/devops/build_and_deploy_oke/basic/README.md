# OCI DevOps Build-And-Deploy-OKE Basic Example

This example is a thin wrapper around the shared **OCI DevOps build-and-deploy-oke** pattern.

It demonstrates a basic public CI/CD flow made of:

- one DevOps project
- one OKE cluster with supporting VCN and subnets
- two mirrored GitHub repositories
- two OCIR repositories for image and Helm artifacts
- one build pipeline that builds an image and packages a Helm chart
- one deploy pipeline that is ready to deploy the chart to OKE

## Files

- `landing-zone.yaml`: payload describing the build-and-deploy-oke pattern
- `main.tf`: thin wrapper around the shared pattern
- `providers.tf`: OCI provider configuration
- `variables.tf`: provider and secret inputs
- `outputs.tf`: useful outputs
- `terraform.tfvars.example`: example provider values

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu plan
```

## Notes

- `region` is the workload region for DevOps, OCIR, OKE, logging, and notifications
- `iam_home_region` is the OCI home region for IAM resources and defaults to `region` when omitted
- `github_pat_secret_ocid` must point to an OCI Vault secret containing the GitHub personal access token
- `github_pat_secret_compartment_ocid` should point to the compartment that contains that Vault secret
- `ocir_user_name` and `ocir_user_password` are used by the Helm build stage to authenticate to OCIR and push chart packages
- `app_branch` is set to `master` because `foggykitchen-hello-world` still uses `master`
- `helm_branch` is set to `main` because `helm-foggykitchen-hello-world` uses `main`
- the public scaffold currently creates separate build and deploy pipelines, but it does not yet wire an automatic build-to-deploy trigger

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
