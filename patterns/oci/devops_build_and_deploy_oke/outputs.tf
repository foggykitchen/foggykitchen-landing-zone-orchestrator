output "project_id" {
  value = module.devops.project_id
}

output "repository_ids" {
  value = module.devops.repository_ids
}

output "build_pipeline_ids" {
  value = module.devops_pipeline.build_pipeline_ids
}

output "deploy_pipeline_ids" {
  value = module.devops_pipeline.deploy_pipeline_ids
}

output "cluster" {
  value = module.oke.cluster
}

output "ocir" {
  value = {
    image_repository = module.ocir_image.repository_name
    image_prefix     = module.ocir_image.image_prefix
    helm_repository  = module.ocir_helm.repository_name
    helm_namespace   = module.ocir_helm.namespace
    helm_registry    = module.ocir_helm.registry
  }
}
