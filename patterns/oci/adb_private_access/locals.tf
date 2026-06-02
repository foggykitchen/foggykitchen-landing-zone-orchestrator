locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  workload     = try(local.config.workload, {})
  data_layer   = try(local.config.data, {})

  tenancy_ocid     = local.cloud.tenancy_ocid
  compartment_ocid = local.cloud.compartment_ocid
  region           = try(local.cloud.workload_region, local.cloud.home_region)
  defined_tags     = try(local.landing_zone.defined_tags, {})
  freeform_tags    = try(local.landing_zone.freeform_tags, {})

  project_name = try(local.landing_zone.name, "fk-oci-adb-private-access-dev")

  network = try(local.architecture.network, {})
  client  = try(local.workload.client, {})
  adb     = try(local.data_layer.adb, {})

  vcn_cidr           = try(local.network.vcn_cidr, "10.120.0.0/16")
  client_subnet_cidr = try(local.network.client_subnet_cidr, "10.120.10.0/24")
  adb_subnet_cidr    = try(local.network.adb_subnet_cidr, "10.120.20.0/24")

  client_name                     = try(local.client.name, "${local.project_name}-client")
  client_shape                    = try(local.client.shape, "VM.Standard.E5.Flex")
  client_operating_system         = try(local.client.operating_system, "Oracle Linux")
  client_operating_system_version = try(local.client.operating_system_version, "9")
  client_shape_config             = try(local.client.shape_config, { ocpus = 1, memory_in_gbs = 8 })
  client_ssh_authorized_keys      = try(local.client.ssh_authorized_keys, [])
  client_ssh_ingress_cidr         = try(local.client.ssh_ingress_cidr, "0.0.0.0/0")
  client_cloud_init_override      = try(local.client.cloud_init_override, null)

  adb_database_name          = try(local.adb.database_name, "FoggyKitchenADB")
  adb_display_name           = try(local.adb.display_name, local.adb_database_name)
  adb_admin_password         = local.adb.admin_password
  adb_db_workload            = try(local.adb.db_workload, "OLTP")
  adb_cpu_core_count         = try(local.adb.cpu_core_count, 1)
  adb_storage_size_in_tbs    = try(local.adb.storage_size_tbs, 1)
  adb_free_tier              = try(local.adb.free_tier, false)
  adb_private_endpoint_label = try(local.adb.private_endpoint_label, "fkadbpe")
  adb_autoscaling_enabled    = try(local.adb.is_auto_scaling_enabled, false)

  default_client_user_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/fk-adb-private/README.txt
        owner: root:root
        permissions: "0644"
        content: |
          FoggyKitchen OCI ADB Private Access validation host
          ---------------------------------------------------
          Use this host to validate private SQL*Net reachability to the ADB private endpoint.

          Suggested checks:
            nc -vz <adb-private-endpoint-ip> 1522

    runcmd:
      - [ bash, -lc, "dnf install -y nmap-ncat unzip bind-utils || true" ]
      - [ bash, -lc, "systemctl disable --now firewalld || true" ]
  EOT

  client_user_data = base64encode(coalesce(local.client_cloud_init_override, local.default_client_user_data))
}
