locals {
  config       = yamldecode(templatefile(var.payload_file, var.payload_template_vars))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  architecture = local.config.architecture
  workload     = try(local.config.workload, {})
  data_layer   = try(local.config.data, {})

  location            = nonsensitive(local.cloud.location)
  subscription_id     = nonsensitive(try(local.cloud.subscription_id, null))
  tenant_id           = nonsensitive(try(local.cloud.tenant_id, null))
  resource_group_name = nonsensitive(try(local.cloud.resource_group.name, "rg-${local.project_name}"))
  tags                = nonsensitive(merge(try(local.landing_zone.default_tags, {}), try(local.landing_zone.tags, {})))

  project_name = nonsensitive(try(local.landing_zone.name, "fk-azure-aks-private-acr-dev"))

  network = try(local.architecture.network, {})
  aks     = try(local.data_layer.aks, {})
  jump    = try(local.workload.jump, {})

  vnet_name           = nonsensitive(try(local.network.vnet.name, "${local.project_name}-vnet"))
  vnet_cidr           = nonsensitive(try(local.network.vnet.cidr, "10.180.0.0/16"))
  node_subnet_name    = nonsensitive(try(local.network.node_subnet.name, "snet-${local.project_name}-aks-nodes"))
  node_subnet_cidr    = nonsensitive(try(local.network.node_subnet.cidr, "10.180.10.0/24"))
  jump_subnet_name    = nonsensitive(try(local.network.jump_subnet.name, "snet-${local.project_name}-aks-jump"))
  jump_subnet_cidr    = nonsensitive(try(local.network.jump_subnet.cidr, "10.180.20.0/24"))
  pe_subnet_name      = nonsensitive(try(local.network.private_endpoint_subnet.name, "snet-${local.project_name}-private-endpoint"))
  pe_subnet_cidr      = nonsensitive(try(local.network.private_endpoint_subnet.cidr, "10.180.40.0/24"))
  bastion_subnet_name = "AzureBastionSubnet"
  bastion_subnet_cidr = nonsensitive(try(local.network.bastion_subnet.cidr, "10.180.30.0/26"))

  nat_gateway_name           = nonsensitive(try(local.network.nat_gateway.name, "${local.project_name}-natgw"))
  nat_gateway_public_ip_name = nonsensitive(try(local.network.nat_gateway.public_ip_name, "${local.project_name}-natgw-pip"))
  route_table_name           = nonsensitive(try(local.network.route_table.name, "${local.project_name}-aks-udr"))

  aks_name                    = nonsensitive(local.aks.cluster.name)
  aks_kubernetes_version      = nonsensitive(try(local.aks.cluster.kubernetes_version, "1.34"))
  aks_network_plugin          = nonsensitive(try(local.aks.cluster.network_plugin, "azure"))
  aks_network_policy          = nonsensitive(try(local.aks.cluster.network_policy, null))
  aks_service_cidr            = nonsensitive(try(local.aks.cluster.service_cidr, "10.200.0.0/16"))
  aks_dns_service_ip          = nonsensitive(try(local.aks.cluster.dns_service_ip, "10.200.0.10"))
  aks_private_cluster_enabled = nonsensitive(try(local.aks.cluster.private_cluster_enabled, true))
  aks_outbound_type           = nonsensitive(try(local.aks.cluster.outbound_type, "userDefinedRouting"))
  aks_default_node_count      = nonsensitive(try(local.aks.default_node_pool.node_count, 1))
  aks_default_node_vm_size    = nonsensitive(try(local.aks.default_node_pool.vm_size, "Standard_D2s_v3"))

  aks_acr           = try(local.aks.acr, null)
  acr_name          = nonsensitive(try(local.aks_acr.name, null))
  acr_sku           = nonsensitive(try(local.aks_acr.sku, "Premium"))
  acr_admin_enabled = nonsensitive(try(local.aks_acr.admin_enabled, false))
  acr_public_access = nonsensitive(try(local.aks_acr.public_network_access_enabled, false))
  acr_private_dns_zone_name = nonsensitive(try(
    local.aks_acr.private_dns_zone_name,
    "privatelink.azurecr.io"
  ))
  acr_private_endpoint_name = nonsensitive(try(
    local.aks_acr.private_endpoint_name,
    "pe-${local.project_name}-acr"
  ))
  aks_diagnostics     = nonsensitive(try(local.aks.diagnostics, null))
  aks_additional_pool = nonsensitive(try(local.aks.additional_node_pools, []))
  aks_cmk             = nonsensitive(try(local.aks.cmk, null))

  jump_name                = nonsensitive(try(local.jump.name, "${local.project_name}-jump"))
  jump_shape               = nonsensitive(try(local.jump.shape, "Standard_B1s"))
  jump_admin_username      = nonsensitive(try(local.jump.admin_username, "azureuser"))
  jump_ssh_authorized_keys = nonsensitive(try(local.jump.ssh_authorized_keys, []))
  jump_cloud_init_override = nonsensitive(try(local.jump.cloud_init_override, null))

  default_jump_custom_data = <<-EOT
    #cloud-config
    write_files:
      - path: /opt/fk-aks-basic/README.txt
        owner: root:root
        permissions: "0644"
        content: |
          FoggyKitchen Azure AKS Private ACR validation host
          -----------------------------------------------------------
          Use this host to validate private AKS API and private ACR reachability.

          Suggested checks after apply:
            getent hosts <aks-private-fqdn>
            nc -vz <aks-private-fqdn> 443
            getent hosts <acr-login-server>
            nc -vz <acr-login-server> 443

    runcmd:
      - [ bash, -lc, "apt-get update || true" ]
      - [ bash, -lc, "DEBIAN_FRONTEND=noninteractive apt-get install -y netcat-openbsd dnsutils curl ca-certificates apt-transport-https lsb-release gnupg || true" ]
      - [ bash, -lc, "curl -sL https://aka.ms/InstallAzureCLIDeb | bash || true" ]
      - [ bash, -lc, "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\" && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl || true" ]
  EOT

  jump_custom_data = base64encode(coalesce(local.jump_cloud_init_override, local.default_jump_custom_data))
}
