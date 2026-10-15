# Azure DevOps Build and Deploy AKS Examples

Payload variants for the [devops_build_and_deploy_aks pattern](../../../../patterns/azure/devops_build_and_deploy_aks/README.md).

## Available Variants

- [basic](basic/README.md): one private AKS cluster, private Premium ACR, and a shared jump/Build VM. OIDC authenticates the pipeline to Azure. Build uses the self-hosted pool; Deploy uses a Microsoft-hosted agent with `az aks command invoke` and kubectl.

The application Service is internal (`ClusterIP`). Operator HTTP access uses port-forward through the private AKS API. All deployment instructions, verification results and screenshots are in the basic README.

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**. See [LICENSE](../../../../LICENSE).
