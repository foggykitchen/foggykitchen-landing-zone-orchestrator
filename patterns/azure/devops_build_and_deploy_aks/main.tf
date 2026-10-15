resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "terraform_data" "scope_guardrails" {
  input = local.aks_name

  lifecycle {
    precondition {
      condition     = can(regex("^https://dev[.]azure[.]com/[A-Za-z0-9_-]+/?$", local.devops_organization_url)) && can(regex("^[A-Za-z0-9_. -]+$", local.build_agent_pool)) && can(regex("^[A-Za-z0-9_.-]+$", local.jump_name))
      error_message = "Use https://dev.azure.com/ORGANIZATION and plain pool/VM names without shell metacharacters."
    }
    precondition {
      condition     = local.jump_cloud_init_override == null
      error_message = "This pattern installs its Build agent via cloud-init; workload.jump.cloud_init_override is not supported."
    }
    precondition {
      condition     = length(trimspace(local.build_agent_pool)) > 0 && local.build_agent_pool != "Azure Pipelines"
      error_message = "devops.build.agent_pool_name must name a private-network self-hosted pool."
    }

    precondition {
      condition     = local.aks_private_cluster_enabled == true
      error_message = "devops_build_and_deploy_aks supports only private AKS clusters. Set data.aks.cluster.private_cluster_enabled to true or omit it."
    }

    precondition {
      condition     = local.aks_network_plugin == "azure"
      error_message = "devops_build_and_deploy_aks supports only AKS Azure CNI with network_plugin = \"azure\"."
    }

    precondition {
      condition     = local.aks_outbound_type == "userDefinedRouting"
      error_message = "devops_build_and_deploy_aks supports outbound_type = \"userDefinedRouting\" with an empty route table associated to the AKS node subnet and NAT Gateway egress."
    }

    precondition {
      condition     = length(local.jump_ssh_authorized_keys) == 1
      error_message = "workload.jump.ssh_authorized_keys must contain exactly one SSH public key."
    }

    precondition {
      condition     = local.aks_acr != null && local.acr_name != null
      error_message = "devops_build_and_deploy_aks requires data.aks.acr.name."
    }

    precondition {
      condition     = local.acr_sku == "Premium"
      error_message = "devops_build_and_deploy_aks requires Azure Container Registry sku = \"Premium\" for Private Endpoint support."
    }

    precondition {
      condition     = local.acr_public_access == false
      error_message = "devops_build_and_deploy_aks requires data.aks.acr.public_network_access_enabled = false or omitted."
    }

    precondition {
      condition     = local.aks_diagnostics == null
      error_message = "data.aks.diagnostics is reserved for a later blueprint-tier AKS pattern and is not supported by devops_build_and_deploy_aks."
    }

    precondition {
      condition     = length(local.aks_additional_pool) == 0
      error_message = "data.aks.additional_node_pools is reserved for a later blueprint-tier AKS pattern and is not supported by devops_build_and_deploy_aks."
    }

    precondition {
      condition     = local.aks_cmk == null
      error_message = "data.aks.cmk is reserved for a later blueprint-tier AKS pattern and is not supported by devops_build_and_deploy_aks."
    }
  }
}

module "vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = local.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [local.vnet_cidr]

  subnets = {
    (local.node_subnet_name) = {
      address_prefixes = [local.node_subnet_cidr]
    }

    (local.jump_subnet_name) = {
      address_prefixes = [local.jump_subnet_cidr]
    }

    (local.pe_subnet_name) = {
      address_prefixes                  = [local.pe_subnet_cidr]
      private_endpoint_network_policies = "Disabled"
    }

    (local.bastion_subnet_name) = {
      address_prefixes = [local.bastion_subnet_cidr]
    }
  }

  tags = local.tags
}

module "node_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.0"

  name                = "${local.project_name}-node-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  rules = [
    {
      name                       = "deny-internet-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = local.node_subnet_cidr
      description                = "Deny direct Internet-originated inbound traffic to the AKS node subnet."
    },
    {
      name                       = "allow-internet-egress"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = local.node_subnet_cidr
      destination_address_prefix = "Internet"
      description                = "Allow outbound traffic through the subnet-associated NAT Gateway."
    }
  ]

  subnet_associations = {
    nodes = {
      subnet_id = module.vnet.subnet_ids[local.node_subnet_name]
    }
  }

  tags = local.tags
}

module "jump_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.0"

  name                = "${local.project_name}-jump-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  rules = [
    {
      name                       = "allow-ssh-from-bastion"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = local.bastion_subnet_cidr
      destination_address_prefix = local.jump_subnet_cidr
      description                = "Allow SSH from Azure Bastion to the private jump subnet."
    },
    {
      name                       = "allow-rdp-from-bastion"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = local.bastion_subnet_cidr
      destination_address_prefix = local.jump_subnet_cidr
      description                = "Allow RDP from Azure Bastion if Windows jump hosts are added later."
    },
    {
      name                       = "deny-internet-inbound"
      priority                   = 400
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = local.jump_subnet_cidr
      description                = "Deny direct Internet-originated inbound traffic to the jump subnet."
    },
    {
      name                       = "allow-internet-egress"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = local.jump_subnet_cidr
      destination_address_prefix = "Internet"
      description                = "Allow outbound traffic through the subnet-associated NAT Gateway."
    }
  ]

  subnet_associations = {
    jump = {
      subnet_id = module.vnet.subnet_ids[local.jump_subnet_name]
    }
  }

  tags = local.tags
}

module "routing" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-routing.git?ref=v0.4.2"

  resource_group_name = azurerm_resource_group.this.name

  route_tables = {
    (local.route_table_name) = {
      location   = azurerm_resource_group.this.location
      routes     = []
      subnet_ids = [module.vnet.subnet_ids[local.node_subnet_name]]
    }
  }

  tags = local.tags
}

module "private_dns" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-private-dns.git?ref=v1.0.0"

  resource_group_name    = azurerm_resource_group.this.name
  private_dns_zone_names = [local.acr_private_dns_zone_name]
  vnet_links = {
    aks = {
      vnet_id              = module.vnet.vnet_id
      registration_enabled = false
    }
  }

  tags = local.tags
}

module "acr" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-acr.git?ref=v0.2.0"

  acr_name                      = local.acr_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = local.acr_sku
  admin_enabled                 = local.acr_admin_enabled
  public_network_access_enabled = false
  tags                          = local.tags
}

module "acr_private_endpoint" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-private-endpoint.git?ref=v1.0.0"

  name                           = local.acr_private_endpoint_name
  location                       = azurerm_resource_group.this.location
  resource_group_name            = azurerm_resource_group.this.name
  subnet_id                      = module.vnet.subnet_ids[local.pe_subnet_name]
  private_connection_resource_id = module.acr.acr_id
  subresource_names              = ["registry"]
  private_dns_zone_group_name    = "default"
  private_dns_zone_ids           = [module.private_dns.private_dns_zone_ids[local.acr_private_dns_zone_name]]
  tags                           = local.tags

  depends_on = [
    module.private_dns,
    module.acr
  ]
}

module "nat_gateway_public_ip" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-public-ip.git?ref=v1.0.0"

  name                = local.nat_gateway_public_ip_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

module "nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.0"

  name                = local.nat_gateway_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  create_public_ip = false
  public_ip_id     = module.nat_gateway_public_ip.id

  subnet_associations = {
    aks_nodes = {
      subnet_id = module.vnet.subnet_ids[local.node_subnet_name]
    }
    jump = {
      subnet_id = module.vnet.subnet_ids[local.jump_subnet_name]
    }
  }

  tags = local.tags
}

module "bastion" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-bastion.git?ref=v1.0.0"

  name                = "${local.project_name}-bastion"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  bastion_subnet_id   = module.vnet.subnet_ids[local.bastion_subnet_name]
  create_public_ip    = true
  sku                 = "Standard"
  tunneling_enabled   = true
  ip_connect_enabled  = true
  tags                = local.tags
}

module "aks" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-aks.git?ref=v2.0.0"

  name                = local.aks_name
  location            = azurerm_resource_group.this.location
  create_rg           = false
  resource_group_name = azurerm_resource_group.this.name

  create_networking = false
  vnet_id           = module.vnet.vnet_id
  subnet_id         = module.vnet.subnet_ids[local.node_subnet_name]

  kubernetes_version      = local.aks_kubernetes_version
  network_plugin          = local.aks_network_plugin
  network_policy          = local.aks_network_policy
  service_cidr            = local.aks_service_cidr
  dns_service_ip          = local.aks_dns_service_ip
  private_cluster_enabled = true
  outbound_type           = local.aks_outbound_type

  default_node_count     = local.aks_default_node_count
  default_node_vm_size   = local.aks_default_node_vm_size
  default_node_subnet_id = module.vnet.subnet_ids[local.node_subnet_name]

  additional_node_pools = []
  acr_id                = null
  create_acr            = false
  enable_log_analytics  = false
  create_law            = false

  tags = local.tags

  depends_on = [
    module.node_nsg,
    module.jump_nsg,
    module.routing,
    module.nat_gateway,
    module.acr_private_endpoint,
    terraform_data.scope_guardrails
  ]
}

data "azurerm_role_definition" "acr_pull" {
  name  = "AcrPull"
  scope = module.acr.acr_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope              = module.acr.acr_id
  role_definition_id = data.azurerm_role_definition.acr_pull.role_definition_id
  principal_id       = module.aks.kubelet_object_id

  depends_on = [
    module.aks,
    module.acr_private_endpoint
  ]
}

module "jump_host" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.3.5"

  name                = local.jump_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  deployment_mode   = "vm"
  subnet_id         = module.vnet.subnet_ids[local.jump_subnet_name]
  admin_username    = local.jump_admin_username
  ssh_public_key    = one(local.jump_ssh_authorized_keys)
  vm_size           = local.jump_shape
  custom_data       = local.jump_custom_data
  attach_nsg_to_nic = true
  nsg_id            = module.jump_nsg.id

  tags = local.tags

  depends_on = [
    module.jump_nsg,
    module.nat_gateway,
    module.aks
  ]
}

# The Build agent must have network access to the private ACR endpoint.
# The jump VM installs Docker and the agent. Register it using the on-host helper.
module "devops" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-devops.git?ref=v0.2.0"

  project_name        = local.devops_project_name
  project_description = "Build and deploy the demo application to private AKS"
  service_connection = {
    name              = "fk-azure-oidc"
    subscription_id   = local.subscription_id
    subscription_name = nonsensitive(local.cloud.subscription_name)
  }
  github_service_connections = {
    app = { name = "fk-github-hello-world" }
  }
  variable_groups = {
    configuration = {
      name         = "fk-configuration"
      allow_access = false
      variables = {
        environment       = nonsensitive(try(local.landing_zone.environment, "dev"))
        acrName           = module.acr.acr_name
        acrLoginServer    = module.acr.acr_login_server
        resourceGroupName = azurerm_resource_group.this.name
        aksClusterName    = module.aks.cluster_name
        buildAgentPool    = local.build_agent_pool
      }
    }
  }
}

module "pipeline_push" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-rbac.git?ref=v0.1.4"

  scope                = module.acr.acr_id
  principal_id         = module.devops.principal_id
  role_definition_name = "AcrPush"
}

# Neither Cluster User nor RBAC Writer grants these ARM management actions.
# Run Command can execute privileged cluster commands; restrict this identity
# and the source branch even though its ARM permission set is small.
resource "azurerm_role_definition" "pipeline_command" {
  name        = local.command_role_name
  scope       = azurerm_resource_group.this.id
  description = "Invoke and read AKS Run Command results for the demo pipeline"
  permissions {
    actions = [
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/runcommand/action",
      "Microsoft.ContainerService/managedClusters/commandResults/read"
    ]
  }
  assignable_scopes = [azurerm_resource_group.this.id]
}

module "pipeline_command" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-rbac.git?ref=v0.1.4"

  scope                = module.aks.cluster_id
  principal_id         = module.devops.principal_id
  role_definition_name = azurerm_role_definition.pipeline_command.name
  depends_on           = [azurerm_role_definition.pipeline_command]
}

module "devops_pipeline" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-devops-pipeline.git?ref=v0.2.0"

  project_id            = module.devops.project_id
  pipeline_name         = nonsensitive(try(local.devops.pipeline.name, "fk-build-and-deploy-aks"))
  service_connection_id = module.devops.service_connection_id
  repository = {
    id                    = local.app_repository
    branch_name           = local.app_branch
    service_connection_id = module.devops.github_service_connection_ids["app"]
  }
  yaml_path          = "azure-pipelines-cicd-aks.yml"
  variable_group_ids = module.devops.variable_group_ids
  depends_on         = [module.pipeline_push, module.pipeline_command, azurerm_role_assignment.aks_acr_pull]
}

resource "azuredevops_agent_pool" "build" {
  name           = local.build_agent_pool
  auto_provision = false
  auto_update    = true
  pool_type      = "automation"
}

resource "azuredevops_agent_queue" "build" {
  project_id    = module.devops.project_id
  agent_pool_id = azuredevops_agent_pool.build.id
}

resource "azuredevops_pipeline_authorization" "build_queue" {
  project_id  = module.devops.project_id
  resource_id = azuredevops_agent_queue.build.id
  type        = "queue"
  pipeline_id = module.devops_pipeline.pipeline_id
}
