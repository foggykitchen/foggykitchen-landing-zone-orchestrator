# Azure Private Endpoint Landing Zone

This example provides one payload for the shared **Azure private endpoint orchestrator pattern**.

![Azure private endpoint storage private link architecture](diagrams/azure_private_endpoint_storage_private_link_architecture.png)

---

## 🎯 Purpose

The goal of this example is to show a **cross-VNet private endpoint consumption pattern** built around a router VM:

- private-first storage
- private endpoint placement in the data spoke
- private DNS integration for storage private link
- router-VM-based transit from the app spoke to the data spoke
- workload validation VMs in both spokes

---

## ✨ What the example does

This example composes:

- one resource group
- one hub VNet
- one app spoke VNet
- one data spoke VNet
- hub-to-spoke peering with forwarded traffic enabled
- one router VM in `hub.shared`
- one NIC-level router NSG named `nsg-fk-router-01`
- one Linux VM in `app.backend` that mounts Azure Files over Private Link
- one Linux VM in `data.database`
- one route table on `app.backend`
- one route table on `data.database`
- one route table on `data.private_endpoints`
- one private-first Storage Account
- one private endpoint for `file` in `data.private_endpoints`
- private DNS zones for storage private link
- NAT Gateway on selected private subnets
- Azure Bastion in the hub

The result is a pattern where the application VM in the app spoke can reach storage private endpoints hosted in the data spoke through the router VM transit path. The private endpoint subnet also gets an explicit routed return path back to the app spoke.
The app VM is bootstrapped with cloud-init that mounts the Azure Files share through the private endpoint path and writes a proof file after the mount succeeds.

---

## 📂 Pattern And Payload

The shared pattern lives in:

- [`patterns/azure/private_endpoint`](../../../../../patterns/azure/private_endpoint)

This example contributes:

- [`landing-zone.yaml`](landing-zone.yaml)
- a thin wrapper [`main.tf`](main.tf)
- provider configuration
- cloud-init scripts under [`scripts/`](scripts)

The pattern reuses the shared `hub_spoke` orchestrator and layers storage plus private endpoints on top.
This example intentionally uses the richer routed variant of the shared Azure foundation rather than the basic scaffold because the consuming workload lives in a different spoke than the private endpoints.
The Azure Files mount bootstrap is rendered from the reference `cloud-init-azurefiles.yaml.tpl` pattern and injected only after the Storage Account exists.

---

## 🧩 Module Map

- `terraform-az-fk-vnet` for hub and spoke VNets
- `terraform-az-fk-vnet-peering` for connectivity
- `terraform-az-fk-routing` for route tables and UDRs
- `terraform-az-fk-nsg` for subnet-level and router NIC-level security
- `terraform-az-fk-public-ip` for NAT public identity
- `terraform-az-fk-natgw` for outbound egress
- `terraform-az-fk-bastion` for secure operator access
- `terraform-az-fk-compute` for the router VM and validation VMs
- `terraform-az-fk-storage` for the Storage Account
- `terraform-az-fk-private-endpoint` for storage private endpoints

---

## 🚀 Deployment

OpenTofu:

```bash
tofu init
tofu plan
tofu apply
```

Terraform:

```bash
terraform init
terraform plan
terraform apply
```

If you want to inject your own public key instead of generating one automatically, pass:

```bash
tofu apply -var="admin_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

For local provisioning of the Azure File Share, also pass the public IP of the machine running OpenTofu:

```bash
tofu apply \
  -var="provisioner_public_ip=<your-public-ip-or-cidr>" \
  -var="admin_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

Why this is needed:

- the Storage Account stays locked down by network rules
- the local OpenTofu runner still needs temporary data-plane access to create the Azure File Share
- the application VM itself continues to consume the share through Private Endpoint resolution and routed hub-and-spoke transit

This is an Azure provisioning limitation workaround, not the intended runtime access model.
You may therefore see a public IP allowlist entry in the Storage Account networking view even though the workload path itself is private-only.

What this means in practice:

- the Storage Account is still deployed as a private-first service with `default_action = Deny`
- the `provisioner_public_ip` variable only opens a narrow exception for the machine running OpenTofu
- the exception exists so Terraform/OpenTofu can create the Azure File Share over the Storage data plane
- `vm-fk-app-pe-01` does not use that public path and still mounts Azure Files through Private DNS, Private Endpoint, and router-VM transit
- after provisioning, you can remove or tighten the temporary IP rule if your operating model requires it

---

## 📤 Expected Outputs

- hub and spoke VNet IDs
- subnet IDs
- Bastion name
- route table IDs
- VM private IPs for `hubrouter`, `app01`, and `db01`
- storage account name and ID
- storage file share names
- private endpoint IDs
- private endpoint private IPs
- private DNS zone IDs
- generated admin SSH private key PEM when `admin_ssh_public_key` is left empty

---

## 🧪 Validation

The ultimate proof for this pattern is a real cross-VNet access test performed through Azure Bastion.

Suggested flow:

- open a Bastion session to `vm-fk-app-pe-01`
- confirm storage private-link name resolution from the app spoke
- test reachability to `vm-fk-db-pe-01` through the router VM
- confirm that the private endpoint subnet participates in the same routed return path
- confirm that the Azure Files share is mounted on the app VM through the private endpoint path

From `vm-fk-app-pe-01`:

```bash
nslookup fkazpeprivdev01.file.core.windows.net
ping -c 4 10.30.1.4
traceroute 10.30.1.4
nc -zv 10.30.1.4 22
mount | grep azurefiles
ls -la /mnt/azurefiles
```

Expected behavior:

- storage names resolve to private-link addresses
- `app01` reaches `db01` through the router VM in `hub.shared`
- `traceroute` shows the transit hop through `10.10.1.4`
- the same routed path makes private endpoint consumption possible from the app spoke
- the dedicated route table on `data.private_endpoints` avoids relying on implicit return-path behavior
- the Azure Files share is mounted on `app01` and contains a proof file written by cloud-init

---

## 🖥️ Azure Portal View

The screenshots below show the deployed Azure footprint, the file private endpoint DNS integration, and the final runtime proof from `vm-fk-app-pe-01`.
Together they confirm that the Storage Account, Private Endpoint, Private DNS, and routed mount path are all working as one end-to-end pattern.

![Azure private endpoint storage private link portal overview](diagrams/azure_private_endpoint_storage_private_link_portal01.png)

`portal01` shows the full resource group scope, including the hub/app/data VNets, router VM, Bastion, Storage Account, private endpoints, route tables, and NAT resources.

![Azure private endpoint storage private link file DNS integration](diagrams/azure_private_endpoint_storage_private_link_portal02.png)

`portal02` shows the `pe-fk-storage-file-dev` private endpoint DNS configuration, including the private IP `10.30.2.5` and the `privatelink.file.core.windows.net` zone integration.

![Azure private endpoint storage private link app VM mount proof](diagrams/azure_private_endpoint_storage_private_link_portal03.png)

`portal03` shows the final proof on `vm-fk-app-pe-01`: private DNS resolution to the file private endpoint, a mounted Azure Files share, and the `codex-proof.txt` file created on the mounted path.

---

## 🧹 Cleanup

```bash
tofu destroy
```

---

## ⚠️ Known Limitations

- This example uses a lightweight router VM, not Azure Firewall.
- It focuses on Storage private endpoints first.
- It does not yet add Key Vault, SQL, or ACR endpoint variants.
- The Azure File Share creation step currently relies on a temporary runner IP allowlist entry passed as `provisioner_public_ip`.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
