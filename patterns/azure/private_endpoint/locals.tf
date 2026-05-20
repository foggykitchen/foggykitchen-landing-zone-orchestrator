locals {
  config                  = yamldecode(file(var.payload_file))
  landing_zone            = local.config.landing_zone
  cloud                   = local.config.cloud
  features                = local.config.features
  private_dns             = local.config.private_dns
  storage                 = local.config.storage
  private_endpoints       = local.config.private_endpoints
  compute_storage_mounts  = try(local.config.compute_storage_mounts, { enabled = false })
  location                = local.cloud.location
  resource_group_name     = local.cloud.resource_group.name
  tags                    = merge(local.landing_zone.default_tags, { owner = local.landing_zone.owner })
  storage_runner_ip_rules = trimspace(var.provisioner_public_ip) != "" ? [trimspace(var.provisioner_public_ip)] : []

  storage_subnet_ids = distinct(compact(
    try(local.storage.network_rules.virtual_network_subnet_refs, [])
  ))

  resolved_storage_subnet_ids = [
    for subnet_ref in local.storage_subnet_ids :
    module.hub_spoke.subnet_ids[split(".", subnet_ref)[0]][split(".", subnet_ref)[1]]
  ]

  resolved_private_endpoints = {
    for endpoint_key, endpoint in try(local.private_endpoints.endpoints, {}) : endpoint_key => {
      name              = endpoint.name
      subnet_id         = module.hub_spoke.subnet_ids[split(".", endpoint.subnet_ref)[0]][split(".", endpoint.subnet_ref)[1]]
      subresource_names = endpoint.subresource_names
      private_dns_zone_ids = [
        for zone_name in endpoint.private_dns_zone_names : module.hub_spoke.private_dns_zone_ids[zone_name]
      ]
      private_ip_address = try(endpoint.private_ip_address, null)
    }
  }

  compute_storage_mounts_mount = try(local.compute_storage_mounts.mount_azure_files, { enabled = false })

  compute_storage_mounts_custom_data = local.features.compute && try(local.compute_storage_mounts.enabled, false) && try(local.compute_storage_mounts_mount.enabled, false) && local.storage.enabled ? base64encode(templatefile("${path.module}/templates/cloud-init-azurefiles.yaml.tpl", {
    storage_account_name = module.storage[0].storage_account_name
    storage_account_key  = module.storage[0].primary_access_key
    fqdn                 = "${module.storage[0].storage_account_name}.file.core.windows.net"
    file_share_name      = local.compute_storage_mounts_mount.share_name
    mount_path           = try(local.compute_storage_mounts_mount.mount_path, "/mnt/azurefiles")
  })) : null
}
