output "project_id" {
  description = "OCI DevOps project OCID."
  value       = module.devops.project_id
}

output "repository_ids" {
  description = "Map of mirrored DevOps repository OCIDs."
  value       = module.devops.repository_ids
}

output "deploy_artifact_ids" {
  description = "Map of deploy artifact OCIDs."
  value       = module.devops.deploy_artifact_ids
}

output "build_pipeline_ids" {
  description = "Map of build pipeline OCIDs."
  value       = module.devops_pipeline.build_pipeline_ids
}

output "build_stage_ids" {
  description = "Map of build stage OCIDs keyed by pipeline:stage."
  value       = module.devops_pipeline.build_stage_ids
}

output "ocir" {
  description = "Structured summary of the OCIR repository used by the pattern."
  value = {
    repository_id   = module.ocir.repository_id
    repository_name = module.ocir.repository_name
    image_prefix    = module.ocir.image_prefix
    latest_image    = module.ocir.latest_image
  }
}
