# Architecture and Screenshots

These JPGs document the Azure DevOps private AKS example. The architecture diagram and seven screenshots are embedded and explained in the [example README](../README.md#screenshots).

- `azure_devops_build_and_deploy_aks_basic_architecture.jpg`: architecture overview.
- `azure_devops_build_and_deploy_aks_basic_resource_group.jpg`: provisioned Azure resources.
- `azure_devops_build_and_deploy_aks_basic_aks_networking.jpg`: private AKS API configuration.
- `azure_devops_build_and_deploy_aks_basic_acr_networking.jpg`: approved ACR Private Endpoint.
- `azure_devops_build_and_deploy_aks_basic_acr_public_access.jpg`: disabled ACR public access.
- `azure_devops_build_and_deploy_aks_basic_agent_pool.jpg`: successful Build job on the shared jump/Build VM.
- `azure_devops_build_and_deploy_aks_basic_pipeline_run.jpg`: successful Build and Deploy stages.
- `azure_devops_build_and_deploy_aks_basic_deploy_logs.jpg`: rollout, pod and image digest.

The diagram summarizes the infrastructure and image flow; the README explains the separate Microsoft-hosted Deploy path through ARM Run Command. Application HTTP test results are documented as commands/output rather than an additional screenshot. The test environment has been destroyed; captures preserve the deployment evidence.
