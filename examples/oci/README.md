# OCI Examples

This directory contains **OCI-focused payload examples** organized by architecture domain.

---

## 🎯 Purpose

The goal of this section is to group OCI examples in a way that stays readable as more network, platform, and workload variants are added.

Current emphasis:

- BaseDB (Oracle Base Database VM systems) with private access through OCI Bastion Service
- ADB-oriented private access patterns
- networking-oriented landing zone patterns
- DRG and LPG-based connectivity models
- multiregion compute failover patterns
- DevOps-oriented build and delivery patterns
- functions-oriented authenticated API patterns
- functions-oriented event-driven data patterns
- functions-oriented bulk and event-driven data patterns

---

## 📂 Available OCI Domains

- [Database service examples — BaseDB](database/README.md)
- [ADB examples](adb/README.md)
- [Networking examples](networking/README.md)
- [Multiregion examples](multiregion/README.md)
- [DevOps examples](devops/README.md)
- [Functions examples](functions/README.md)

---

## OCI BaseDB Private Access

The [BaseDB private-access basic example](database/basedb/private_access/basic/README.md), added in **v2.2.0**, deploys a private Oracle Base Database VM system and an Oracle Linux 9 validation host in two private subnets. OCI Bastion Service provides Managed SSH access; NSGs, NAT Gateway and Service Gateway control network access without an Internet Gateway.

The example uses **VM.BaseDB.x86, 4 ECPUs, 256 GB, Standard Edition and LICENSE_INCLUDED** in an existing compartment. Its README includes the architecture diagram, console screenshots, successful live SSH and TCP/1521 validation, cleanup results, and the first-boot retries observed during deployment. BaseDB is a paid service with no Free Tier.

- [BaseDB examples](database/basedb/README.md)
- [Reusable BaseDB pattern](../../patterns/oci/basedb_private_access/README.md)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
