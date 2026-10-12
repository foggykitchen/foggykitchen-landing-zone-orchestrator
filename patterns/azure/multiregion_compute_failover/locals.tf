locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  workload     = local.config.workload
  frontdoor    = local.config.frontdoor

  subscription_id     = nonsensitive(try(local.cloud.subscription_id, null))
  tenant_id           = nonsensitive(try(local.cloud.tenant_id, null))
  primary_location    = nonsensitive(try(local.cloud.primary_location, local.cloud.location))
  standby_location    = nonsensitive(local.cloud.standby_location)
  resource_group_name = nonsensitive(try(local.cloud.resource_group.name, "rg-${local.project_name}"))
  tags                = nonsensitive(merge(try(local.landing_zone.default_tags, {}), try(local.landing_zone.tags, {})))

  project_name = nonsensitive(try(local.landing_zone.name, "fk-azure-multiregion-compute-failover-dev"))

  network = try(local.architecture.network, {})
  primary = try(local.workload.primary_site, {})
  standby = try(local.workload.standby_site, {})

  primary_vnet_name       = nonsensitive(try(local.network.primary_vnet.name, "${local.project_name}-primary-vnet"))
  primary_vnet_cidr       = nonsensitive(try(local.network.primary_vnet.cidr, "10.210.0.0/16"))
  primary_app_subnet_name = nonsensitive(try(local.network.primary_app_subnet.name, "snet-fk-primary-app"))
  primary_app_subnet_cidr = nonsensitive(try(local.network.primary_app_subnet.cidr, "10.210.20.0/24"))

  standby_vnet_name       = nonsensitive(try(local.network.standby_vnet.name, "${local.project_name}-standby-vnet"))
  standby_vnet_cidr       = nonsensitive(try(local.network.standby_vnet.cidr, "10.220.0.0/16"))
  standby_app_subnet_name = nonsensitive(try(local.network.standby_app_subnet.name, "snet-fk-standby-app"))
  standby_app_subnet_cidr = nonsensitive(try(local.network.standby_app_subnet.cidr, "10.220.20.0/24"))

  primary_name = nonsensitive(try(local.primary.name, "${local.project_name}-primary"))
  standby_name = nonsensitive(try(local.standby.name, "${local.project_name}-standby"))

  admin_username = nonsensitive(try(local.workload.compute.admin_username, "azureuser"))
  ssh_public_key = local.workload.compute.ssh_public_key
  vm_size        = nonsensitive(try(local.workload.compute.vm_size, "Standard_B2s"))
  image_reference = nonsensitive(try(local.workload.compute.image_reference, {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }))
  primary_instance_count = nonsensitive(try(local.primary.instance_count, 2))
  standby_instance_count = nonsensitive(try(local.standby.instance_count, 1))

  primary_autoscale_enabled = nonsensitive(try(local.primary.enable_autoscale, false))
  standby_autoscale_enabled = nonsensitive(try(local.standby.enable_autoscale, false))

  primary_autoscale_min_instances = nonsensitive(try(local.primary.autoscaling.min_instances, local.primary_instance_count))
  primary_autoscale_max_instances = nonsensitive(try(local.primary.autoscaling.max_instances, max(local.primary_instance_count, local.primary_autoscale_min_instances)))
  primary_scale_out_threshold     = nonsensitive(try(local.primary.autoscaling.scale_out_cpu_threshold, 70))
  primary_scale_in_threshold      = nonsensitive(try(local.primary.autoscaling.scale_in_cpu_threshold, 30))

  standby_autoscale_min_instances = nonsensitive(try(local.standby.autoscaling.min_instances, local.standby_instance_count))
  standby_autoscale_max_instances = nonsensitive(try(local.standby.autoscaling.max_instances, max(local.standby_instance_count, local.standby_autoscale_min_instances)))
  standby_scale_out_threshold     = nonsensitive(try(local.standby.autoscaling.scale_out_cpu_threshold, 70))
  standby_scale_in_threshold      = nonsensitive(try(local.standby.autoscaling.scale_in_cpu_threshold, 30))

  load_balancer = try(local.workload.load_balancer, {})
  lb_sku        = nonsensitive(try(local.load_balancer.sku, "Standard"))
  lb_probe = nonsensitive(try(local.load_balancer.probe, {
    name                = "http-health-probe"
    protocol            = "Http"
    port                = 80
    interval_in_seconds = 5
    number_of_probes    = 2
    request_path        = "/"
  }))
  lb_rule = nonsensitive(try(local.load_balancer.rule, {
    name                    = "http-rule"
    protocol                = "Tcp"
    frontend_port           = 80
    backend_port            = 80
    idle_timeout_in_minutes = 4
    disable_outbound_snat   = true
  }))

  primary_lb_name  = nonsensitive(try(local.load_balancer.primary_name, "lb-${local.primary_name}"))
  standby_lb_name  = nonsensitive(try(local.load_balancer.standby_name, "lb-${local.standby_name}"))
  primary_pip_name = nonsensitive(try(local.load_balancer.primary_public_ip_name, "pip-${local.primary_name}-lb"))
  standby_pip_name = nonsensitive(try(local.load_balancer.standby_public_ip_name, "pip-${local.standby_name}-lb"))

  primary_nat_gateway_name           = nonsensitive(try(local.network.primary_nat_gateway.name, "natgw-${local.primary_name}"))
  primary_nat_gateway_public_ip_name = nonsensitive(try(local.network.primary_nat_gateway.public_ip_name, "pip-${local.primary_name}-natgw"))
  standby_nat_gateway_name           = nonsensitive(try(local.network.standby_nat_gateway.name, "natgw-${local.standby_name}"))
  standby_nat_gateway_public_ip_name = nonsensitive(try(local.network.standby_nat_gateway.public_ip_name, "pip-${local.standby_name}-natgw"))

  frontdoor_name          = nonsensitive(try(local.frontdoor.name, "${local.project_name}-afd"))
  frontdoor_endpoint_name = nonsensitive(try(local.frontdoor.endpoint_name, "${local.project_name}-endpoint"))
  frontdoor_origin_group  = nonsensitive(try(local.frontdoor.origin_group_name, "multiregion-web"))
  frontdoor_route_name    = nonsensitive(try(local.frontdoor.route_name, "default"))
  frontdoor_sku_name      = nonsensitive(try(local.frontdoor.sku_name, "Standard_AzureFrontDoor"))

  primary_default_custom_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/foggykitchen-site/index.html
        permissions: "0644"
        content: |
          <html><body><h1>${local.primary_name}</h1><p>FoggyKitchen Azure multiregion compute failover - primary site</p></body></html>
      - path: /etc/systemd/system/foggykitchen-demo.service
        permissions: "0644"
        content: |
          [Unit]
          Description=FoggyKitchen Azure multiregion demo HTTP service
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
      - apt-get update || true
      - DEBIAN_FRONTEND=noninteractive apt-get install -y python3 || true
      - systemctl daemon-reload
      - systemctl enable foggykitchen-demo.service
      - systemctl restart foggykitchen-demo.service
    EOT

  standby_default_custom_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/foggykitchen-site/index.html
        permissions: "0644"
        content: |
          <html><body><h1>${local.standby_name}</h1><p>FoggyKitchen Azure multiregion compute failover - standby site</p></body></html>
      - path: /etc/systemd/system/foggykitchen-demo.service
        permissions: "0644"
        content: |
          [Unit]
          Description=FoggyKitchen Azure multiregion demo HTTP service
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
      - apt-get update || true
      - DEBIAN_FRONTEND=noninteractive apt-get install -y python3 || true
      - systemctl daemon-reload
      - systemctl enable foggykitchen-demo.service
      - systemctl restart foggykitchen-demo.service
    EOT

  primary_custom_data = base64encode(try(local.primary.cloud_init_override, local.workload.compute.cloud_init_override.primary, local.primary_default_custom_data))
  standby_custom_data = base64encode(try(local.standby.cloud_init_override, local.workload.compute.cloud_init_override.standby, local.standby_default_custom_data))
}
