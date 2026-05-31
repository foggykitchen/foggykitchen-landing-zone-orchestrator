output "project_id" {
  value = module.landing_zone.project_id
}

output "build_pipeline_ids" {
  value = module.landing_zone.build_pipeline_ids
}

output "deploy_pipeline_ids" {
  value = module.landing_zone.deploy_pipeline_ids
}

output "cluster" {
  value     = module.landing_zone.cluster
  sensitive = true
}

output "ocir" {
  value     = module.landing_zone.ocir
  sensitive = true
}
