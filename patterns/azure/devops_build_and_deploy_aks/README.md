# Azure DevOps Build and Deploy AKS Pattern

This public teaser-tier pattern composes a private AKS cluster, Premium ACR with a Private Endpoint, and an Azure DevOps YAML pipeline. The infrastructure is self-contained: it directly composes the same networking and AKS modules as `aks_private_acr`, together with the DevOps, pipeline, and RBAC modules.

## Summary

- one VNet with node, jump, ACR Private Endpoint, and Azure Bastion subnets
- node and jump NSGs, an empty node route table, and NAT Gateway egress
- private AKS with Azure CNI, a single system pool, and kubelet `AcrPull`
- Premium ACR with public network access disabled, a `registry` Private Endpoint, and Private DNS
- Azure Bastion and a private Linux jump host (`Standard_B2s` in the example), also used as the self-hosted Build agent
- one private Azure DevOps project, GitHub source connection, ARM OIDC connection named `fk-azure-oidc`, and restricted `fk-configuration` variable group
- one YAML pipeline definition using `foggykitchen/foggykitchen-hello-world/azure-pipelines-cicd-aks.yml`
- Build: checkout, Docker build, HTTP smoke test, OIDC ACR push, and immutable image metadata
- Deploy: `AzureCLI@2` invokes `kubectl` through the AKS ARM Run Command API, waits for rollout, and reports pod image IDs and the ClusterIP service

Build runs on the private jump VM. Cloud-init installs Docker, Azure CLI, kubectl and the Azure Pipelines Linux x64 agent (version `5.280.0`, with a pinned SHA-256 checksum from the [upstream release](https://github.com/microsoft/azure-pipelines-agent/releases/tag/v5.280.0)). Terraform creates the self-hosted pool, its project queue and authorization for this pipeline only. Deploy uses a Microsoft-hosted `ubuntu-24.04` agent.

After apply, connect through Bastion, wait for cloud-init, then run `sudo /usr/local/sbin/fk-register-build-agent`. The helper registers the agent interactively and installs/starts its systemd service as the dedicated `azagent` account with Docker access. Supply a short-lived PAT with **Agent Pools: Read & manage** when prompted, from a user allowed to administer this pool; do not pass it to Terraform. The registration PAT is not persisted by the helper. The agent stores its own service credentials on the VM. Registration follows [Microsoft's Linux agent setup](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/linux-agent?view=azure-devops). The shared jump/Build VM is intended for this demo; Docker access gives the agent effective root access on that VM.

It deliberately excludes:

- canary rollout stages
- blue-green rollout stages
- premium blueprint integrations
- manual-approval gates
- public AKS API and public ACR access
- image signing, scanning, and promotion workflows
- Azure Firewall, hub-and-spoke transit, customer-managed keys, additional node pools, autoscaling, diagnostics, and multi-region configuration

Canary rollout stages, blue-green rollout stages, and premium blueprint integrations belong in a future private Enterprise blueprint.

### Network and identity decisions

A Microsoft-hosted agent cannot push directly to an ACR with public access disabled. Build therefore uses `devops.build.agent_pool_name`, with Docker, Azure CLI, Bash, curl, and access to the registry login and regional data endpoints over TCP 443. The agent needs outbound HTTPS access to Azure DevOps, GitHub, Entra ID, ARM, and the Docker base-image registry. Private DNS must resolve ACR to its Private Endpoint. This explicitly changes the Build agent placement from the existing Container Apps example while retaining its build/test/push steps. See [Microsoft's ACR Private Link restrictions](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-private-link).

The DevOps module creates an **Entra application and service principal**, federated to the ARM OIDC endpoint. It does not create a user-assigned managed identity. The pipeline service principal receives `AcrPush` at ACR scope and the custom role `<landing_zone.name> AKS Run Command` at cluster scope. That role has exactly:

- `Microsoft.ContainerService/managedClusters/read`
- `Microsoft.ContainerService/managedClusters/runcommand/action`
- `Microsoft.ContainerService/managedClusters/commandResults/read`

The live built-in role definitions inspected during development show neither `Azure Kubernetes Service Cluster User Role` nor `Azure Kubernetes Service RBAC Writer` grants Run Command. Live pipeline trials confirmed both built-in roles are insufficient: Cluster User was denied `runCommand/action` (run 7), and RBAC Writer was denied cluster `read` (run 8). The custom role succeeded in end-to-end OIDC runs 6 and 9. See the example README for command output and run links. Run Command permits privileged commands inside the cluster; restrict pipeline source write access accordingly. See [AKS Run Command prerequisites](https://learn.microsoft.com/en-us/azure/aks/access-private-cluster).

Plain `kubectl` was selected to keep this demo to one Deployment and ClusterIP Service, reuse the pushed digest, and avoid attaching chart files. No Helm file-size failure was observed or claimed. The YAML bootstraps the Deployment and Service, updates the image, waits for rollout, compares the Deployment image reference, and prints runtime image IDs. All deploy logic lives in YAML; there is no Terraform-managed Kubernetes deploy stage.

## Payload Scope

The pattern consumes the same infrastructure blocks as `aks_private_acr`:

- `architecture.network.vnet`, `node_subnet`, `jump_subnet`, `private_endpoint_subnet`, `bastion_subnet`
- optional `architecture.network.nat_gateway` and `route_table`
- `workload.jump`
- `data.aks.cluster`, `default_node_pool`, and `acr`

It additionally consumes:

- `cloud.subscription_id`, `tenant_id`, `subscription_name`, `location`, and `resource_group.name`
- `devops.project.name`
- `devops.github.repository` (default `foggykitchen/foggykitchen-hello-world`)
- `devops.github.branch` (default `master`)
- `devops.organization_url` (same organization as the Azure DevOps provider)
- `devops.build.agent_pool_name` (name of the new Terraform-managed pool)
- optional `devops.pipeline.name`

`workload.jump.cloud_init_override` is rejected so the required agent bootstrap cannot silently be replaced. Pool names allow letters, digits, spaces, dots, underscores and hyphens. Use a pool name that does not already exist, or import the existing pool before applying.

The optional sensitive `admin_ssh_public_key` module input overrides the jump key in YAML; the example uses it for TLS-generated keys so the payload remains known during plan.

Provider authentication is supplied by the caller. The GitHub source endpoint uses `AZDO_GITHUB_SERVICE_CONNECTION_PAT`; the caller configures Azure DevOps provider authentication. The basic example uses the Azure CLI session (`use_cli = true`); callers using PAT authentication configure that in their provider instead. Never put tokens in the payload. Pipeline-to-Azure authentication uses OIDC. Guardrails require private AKS, Azure CNI, user-defined routing, Premium private ACR, exactly one jump SSH key, and reject CMK, diagnostics, and additional pools.

## Verified Service Names

- ACR Private Endpoint subresource: `registry`
- ACR Private DNS Zone: `privatelink.azurecr.io`
- ARM service connection: `fk-azure-oidc`
- variable group: `fk-configuration`
- pipeline YAML: `azure-pipelines-cicd-aks.yml`

These identifiers are wired in code. Live deployment results and command evidence are recorded in the [example README](../../../examples/azure/devops/build_and_deploy_aks/basic/README.md#verified-results--2026-10-15).

## Examples

- [`examples/azure/devops/build_and_deploy_aks/basic`](../../../examples/azure/devops/build_and_deploy_aks/basic/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**. See [LICENSE](../../../LICENSE).
