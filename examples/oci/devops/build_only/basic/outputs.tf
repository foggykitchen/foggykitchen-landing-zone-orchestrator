output "project_id" {
  value = module.landing_zone.project_id
}

output "repository_ids" {
  value = module.landing_zone.repository_ids
}

output "build_pipeline_ids" {
  value = module.landing_zone.build_pipeline_ids
}

output "ocir" {
  value = module.landing_zone.ocir
}
