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

  project_name = nonsensitive(try(local.landing_zone.name, "fk-azure-devops-aks-dev"))

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
  jump_shape               = nonsensitive(try(local.jump.shape, "Standard_B2s"))
  jump_admin_username      = nonsensitive(try(local.jump.admin_username, "azureuser"))
  jump_ssh_authorized_keys = var.admin_ssh_public_key == null ? nonsensitive(try(local.jump.ssh_authorized_keys, [])) : [var.admin_ssh_public_key]
  jump_cloud_init_override = nonsensitive(try(local.jump.cloud_init_override, null))

  build_agent_install_script = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y docker.io git curl ca-certificates dnsutils netcat-openbsd python3
    systemctl enable --now docker
    id azagent >/dev/null 2>&1 || useradd --create-home --shell /bin/bash azagent
    usermod -aG docker azagent
    curl -fsSL https://aka.ms/InstallAzureCLIDeb -o /tmp/fk-install-azure-cli.sh
    bash /tmp/fk-install-azure-cli.sh
    kubectl_version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/$kubectl_version/bin/linux/amd64/kubectl" -o /tmp/fk-kubectl
    curl -fsSL "https://dl.k8s.io/release/$kubectl_version/bin/linux/amd64/kubectl.sha256" -o /tmp/fk-kubectl.sha256
    printf '%s  /tmp/fk-kubectl\n' "$(cat /tmp/fk-kubectl.sha256)" | sha256sum --check
    install -m 0755 /tmp/fk-kubectl /usr/local/bin/kubectl
    install -d -o azagent -g azagent -m 0750 /opt/azagent
    curl -fsSL --retry 5 https://download.agent.dev.azure.com/agent/5.280.0/vsts-agent-linux-x64-5.280.0.tar.gz -o /tmp/fk-azagent.tar.gz
    printf '%s  /tmp/fk-azagent.tar.gz\n' 'f0daf1ce526af0b5eebf420249d21689de10faf00ffb0f19851626eb4352d791' | sha256sum --check
    tar -xzf /tmp/fk-azagent.tar.gz -C /opt/azagent
    /opt/azagent/bin/installdependencies.sh
    chown -R azagent:azagent /opt/azagent
    touch /opt/azagent/.bootstrap-complete
  EOT

  build_agent_register_script = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$(id -u)" -ne 0 ]; then
      echo "Run with sudo from an interactive Bastion SSH session." >&2
      exit 1
    fi
    if [ ! -t 0 ]; then
      echo "An interactive terminal is required for the registration credential prompt." >&2
      exit 1
    fi
    if [ ! -f /opt/azagent/.bootstrap-complete ]; then
      echo "Bootstrap is not complete. Check cloud-init status --wait and /var/log/cloud-init-output.log." >&2
      exit 1
    fi
    cd /opt/azagent
    if [ ! -f .agent ]; then
      # config.sh prompts for the PAT; it is never supplied through Terraform,
      # custom_data, command-line arguments, or shell history.
      runuser -u azagent -- ./config.sh --url ${jsonencode(local.devops_organization_url)} --auth pat --pool ${jsonencode(local.build_agent_pool)} --agent ${jsonencode(local.jump_name)} --work _work
    fi
    # Registration does not store the PAT; the agent keeps its own service credentials.
    if [ ! -f .service ]; then
      ./svc.sh install azagent
    fi
    ./svc.sh start
    ./svc.sh status
  EOT

  default_jump_custom_data = join("\n", ["#cloud-config", yamlencode({
    write_files = [
      {
        path        = "/usr/local/sbin/fk-install-build-agent"
        owner       = "root:root"
        permissions = "0700"
        content     = local.build_agent_install_script
      },
      {
        path        = "/usr/local/sbin/fk-register-build-agent"
        owner       = "root:root"
        permissions = "0700"
        content     = local.build_agent_register_script
      }
    ]
    runcmd = [["bash", "/usr/local/sbin/fk-install-build-agent"]]
  })])

  jump_custom_data = base64encode(coalesce(local.jump_cloud_init_override, local.default_jump_custom_data))
}

locals {
  devops                  = local.config.devops
  devops_project_name     = nonsensitive(local.devops.project.name)
  app_repository          = nonsensitive(try(local.devops.github.repository, "foggykitchen/foggykitchen-hello-world"))
  app_branch              = nonsensitive(try(local.devops.github.branch, "master"))
  build_agent_pool        = nonsensitive(local.devops.build.agent_pool_name)
  devops_organization_url = nonsensitive(local.devops.organization_url)
  command_role_name       = "${local.project_name} AKS Run Command"
}
