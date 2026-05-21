# OCI LPG Local Peering Landing Zone

This example provides one payload for the shared **OCI local peering orchestrator pattern**.

![OCI LPG local peering architecture](diagrams/lpg_local_peering_basic_architecture.png)

---

## 🎯 Purpose

The goal of this example is to show a **same-region OCI local peering pattern** for:

- app-to-data VCN connectivity
- private-first workload placement
- explicit LPG-based routing
- simple two-VCN architecture composition

---

## ✨ What the example does

This example composes:

- one app VCN
- one data VCN
- one LPG per VCN
- local peering between both VCNs
- private subnets and security lists
- one private application instance
- one private data instance
- one private load balancer in the app VCN

---

## 📂 Pattern And Payload

The shared pattern lives in:

- [`patterns/oci/lpg_local_peering`](../../../../../patterns/oci/lpg_local_peering)

This example contributes:

- [`landing-zone.yaml`](landing-zone.yaml)
- [`terraform.tfvars.example`](terraform.tfvars.example)
- a thin wrapper [`main.tf`](main.tf)
- provider configuration

---

## 🚀 Deployment

OpenTofu:

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu plan
tofu apply
```

`terraform.tfvars` carries the OCI user-level credentials and SSH key material:

- `user_ocid`
- `fingerprint`
- `private_key_path`
- `admin_ssh_public_key`

`landing-zone.yaml` still carries the OCI scope and architecture intent, including:

- `cloud.region`
- `cloud.tenancy_ocid`
- `cloud.compartment_ocid`
- the VCN, LPG, compute, and load balancer topology

Replace the example OCIDs in `landing-zone.yaml` and the placeholder values in `terraform.tfvars.example` before running `tofu plan` or `tofu apply`.

---

## 📤 Expected Outputs

- LPG IDs
- VCN IDs
- subnet IDs
- private IPs of instances
- private IPs of the load balancer

---

## 🖥️ OCI Console View

The screenshots below provide a lightweight control-plane confirmation of the deployed LPG local peering architecture.

They show the resource inventory, the established local peering relationship, and the regional routing map that visually confirms the two VCNs are connected through LPGs.

**Resource inventory**

![OCI LPG local peering resource inventory](diagrams/lpg_local_peering_basic_oci_console01.png)

**Local peering state**

![OCI LPG local peering console view](diagrams/lpg_local_peering_basic_oci_console02.png)

**Regional routing map**

![OCI LPG local peering routing map](diagrams/lpg_local_peering_basic_oci_console03.png)

---

## 🧹 Cleanup

```bash
tofu destroy
```

---

## ⚠️ Known Limitations

- This example focuses on same-region LPG connectivity only.
- DRG-based transit remains covered by example `03`.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
