locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  workload     = local.config.workload
  dns          = local.config.dns

  tenancy_ocid     = local.cloud.tenancy_ocid
  compartment_ocid = local.cloud.compartment_ocid
  iam_home_region  = local.cloud.home_region
  primary_region   = try(local.cloud.primary_region, local.cloud.workload_region, local.cloud.home_region)
  standby_region   = local.cloud.standby_region
  defined_tags     = try(local.landing_zone.defined_tags, {})
  freeform_tags    = try(local.landing_zone.freeform_tags, {})

  compartment_ocid_plain = nonsensitive(local.compartment_ocid)
  project_name           = local.workload.project.name
  project_name_plain     = nonsensitive(local.project_name)

  network = try(local.architecture.network, {})
  primary = try(local.workload.primary_site, {})
  standby = try(local.workload.standby_site, {})

  primary_vcn_cidr   = try(local.network.primary_vcn_cidr, "10.100.0.0/16")
  primary_lb_subnet  = try(local.network.primary_lb_subnet_cidr, "10.100.10.0/24")
  primary_app_subnet = try(local.network.primary_app_subnet_cidr, "10.100.20.0/24")
  standby_vcn_cidr   = try(local.network.standby_vcn_cidr, "10.110.0.0/16")
  standby_lb_subnet  = try(local.network.standby_lb_subnet_cidr, "10.110.10.0/24")
  standby_app_subnet = try(local.network.standby_app_subnet_cidr, "10.110.20.0/24")

  primary_name = try(local.primary.name, "${local.project_name}-primary")
  standby_name = try(local.standby.name, "${local.project_name}-standby")

  primary_pool_size = try(local.primary.instance_pool_size, 2)
  standby_pool_size = try(local.standby.instance_pool_size, 1)

  primary_autoscale_enabled = try(local.primary.enable_autoscale, false)
  standby_autoscale_enabled = try(local.standby.enable_autoscale, false)

  primary_autoscaling_min_instances     = try(local.primary.autoscaling.min_instances, local.primary_pool_size)
  primary_autoscaling_initial_instances = try(local.primary.autoscaling.initial_instances, local.primary_pool_size)
  primary_autoscaling_max_instances     = try(local.primary.autoscaling.max_instances, max(local.primary_pool_size, local.primary_autoscaling_initial_instances))
  primary_scale_out_cpu_threshold       = try(local.primary.autoscaling.scale_out_cpu_threshold, 70)
  primary_scale_in_cpu_threshold        = try(local.primary.autoscaling.scale_in_cpu_threshold, 25)

  standby_autoscaling_min_instances     = try(local.standby.autoscaling.min_instances, local.standby_pool_size)
  standby_autoscaling_initial_instances = try(local.standby.autoscaling.initial_instances, local.standby_pool_size)
  standby_autoscaling_max_instances     = try(local.standby.autoscaling.max_instances, max(local.standby_pool_size, local.standby_autoscaling_initial_instances))
  standby_scale_out_cpu_threshold       = try(local.standby.autoscaling.scale_out_cpu_threshold, 70)
  standby_scale_in_cpu_threshold        = try(local.standby.autoscaling.scale_in_cpu_threshold, 25)

  compute_shape                    = try(local.workload.compute.shape, "VM.Standard.E5.Flex")
  compute_operating_system         = try(local.workload.compute.operating_system, "Oracle Linux")
  compute_operating_system_version = try(local.workload.compute.operating_system_version, "9")
  compute_shape_config             = try(local.workload.compute.shape_config, { ocpus = 1, memory_in_gbs = 8 })
  ssh_authorized_keys              = try(local.workload.compute.ssh_authorized_keys, [])

  lb_health_checker = try(local.workload.load_balancer.health_checker, {
    protocol = "HTTP"
    port     = 80
    url_path = "/"
  })
  lb_listener = try(local.workload.load_balancer.listener, {
    name     = "http"
    port     = 80
    protocol = "HTTP"
  })
  lb_shape = try(local.workload.load_balancer.shape, "flexible")
  lb_shape_details = try(local.workload.load_balancer.shape_details, {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  })
  primary_lb_name        = try(local.workload.load_balancer.primary_name, "fkpri")
  standby_lb_name        = try(local.workload.load_balancer.standby_name, "fkstd")
  primary_backendset_name = try(local.workload.load_balancer.primary_backend_set_name, "fkpri-bes")
  standby_backendset_name = try(local.workload.load_balancer.standby_backend_set_name, "fkstd-bes")

  dns_zone_name   = local.dns.zone_name
  dns_domain_name = local.dns.domain_name
  dns_policy_name = try(local.dns.display_name, "${local.project_name}-dns-steering")
  anchor_record   = try(local.dns.anchor_record_address, null)
  dns_rules = try(local.dns.rules, [
    {
      rule_type = "FILTER"
      default_answer_data = [
        {
          answer_condition = "answer.isDisabled != true"
          should_keep      = true
        }
      ]
    },
    {
      rule_type = "HEALTH"
    },
    {
      rule_type = "PRIORITY"
      default_answer_data = [
        {
          answer_condition = "answer.pool == 'primary'"
          value            = 0
        },
        {
          answer_condition = "answer.pool == 'standby'"
          value            = 1
        }
      ]
    },
    {
      rule_type     = "LIMIT"
      default_count = 1
    }
  ])

  primary_default_user_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/foggykitchen-site/index.html
        permissions: "0644"
        content: |
          <html><body><h1>${local.primary_name}</h1><p>FoggyKitchen multiregion compute failover - primary site</p></body></html>
      - path: /etc/systemd/system/foggykitchen-demo.service
        permissions: "0644"
        content: |
          [Unit]
          Description=FoggyKitchen multiregion demo HTTP service
          After=network-online.target
          Wants=network-online.target

          [Service]
          Type=simple
          WorkingDirectory=/opt/foggykitchen-site
          ExecStart=/usr/bin/python3 -m http.server 80 --directory /opt/foggykitchen-site
          Restart=always
          RestartSec=5

          [Install]
          WantedBy=multi-user.target
    runcmd:
      - mkdir -p /opt/foggykitchen-site
      - systemctl disable --now firewalld || true
      - systemctl daemon-reload
      - systemctl enable foggykitchen-demo.service
      - systemctl restart foggykitchen-demo.service
    EOT

  standby_default_user_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/foggykitchen-site/index.html
        permissions: "0644"
        content: |
          <html><body><h1>${local.standby_name}</h1><p>FoggyKitchen multiregion compute failover - standby site</p></body></html>
      - path: /etc/systemd/system/foggykitchen-demo.service
        permissions: "0644"
        content: |
          [Unit]
          Description=FoggyKitchen multiregion demo HTTP service
          After=network-online.target
          Wants=network-online.target

          [Service]
          Type=simple
          WorkingDirectory=/opt/foggykitchen-site
          ExecStart=/usr/bin/python3 -m http.server 80 --directory /opt/foggykitchen-site
          Restart=always
          RestartSec=5

          [Install]
          WantedBy=multi-user.target
    runcmd:
      - mkdir -p /opt/foggykitchen-site
      - systemctl disable --now firewalld || true
      - systemctl daemon-reload
      - systemctl enable foggykitchen-demo.service
      - systemctl restart foggykitchen-demo.service
    EOT

  primary_user_data = base64encode(try(local.primary.cloud_init_override, local.workload.compute.cloud_init_override.primary, local.primary_default_user_data))

  standby_user_data = base64encode(try(local.standby.cloud_init_override, local.workload.compute.cloud_init_override.standby, local.standby_default_user_data))
}
