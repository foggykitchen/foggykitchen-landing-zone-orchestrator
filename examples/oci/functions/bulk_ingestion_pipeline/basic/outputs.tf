output "objectstorage" {
  value     = module.landing_zone.objectstorage
  sensitive = true
}

output "streaming" {
  value = module.landing_zone.streaming
}

output "service_connector" {
  value = module.landing_zone.service_connector
}

output "events_rule" {
  value     = module.landing_zone.events_rule
  sensitive = true
}

output "function_ids" {
  value = module.landing_zone.function_ids
}

output "adb" {
  value     = module.landing_zone.adb
  sensitive = true
}
