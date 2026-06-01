output "objectstorage" {
  value = {
    namespace    = module.objectstorage.namespace
    bucket_ids   = module.objectstorage.bucket_ids
    bucket_names = module.objectstorage.bucket_names
  }
  sensitive = true
}

output "streaming" {
  value = {
    stream_pool_id            = module.streaming.stream_pool_id
    stream_pool_endpoint_fqdn = module.streaming.stream_pool_endpoint_fqdn
    stream_ids                = module.streaming.stream_ids
  }
}

output "service_connector" {
  value = {
    id    = module.sch.service_connector_id
    state = module.sch.service_connector_state
  }
}

output "events_rule" {
  value = {
    id    = module.event.rule_id
    name  = module.event.rule_name
    state = module.event.rule_state
  }
  sensitive = true
}

output "function_ids" {
  value = {
    fnbulkload  = module.fnbulkload.oci_app_fn.fn_ocid
    fncollector = module.fncollector.oci_app_fn.fn_ocid
    fnadbsetup  = module.fnadbsetup.oci_app_fn.fn_ocid
  }
}

output "adb" {
  value     = module.adb.adb_database
  sensitive = true
}
