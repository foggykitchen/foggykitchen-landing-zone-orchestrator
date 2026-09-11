# Examples

This directory contains **payload-driven example deployments** for the shared landing zone patterns defined under `patterns/`.

---

## 🎯 Purpose

The goal of the `examples/` tree is to provide:

- runnable payload variants
- thin wrappers around shared patterns
- cloud-specific and domain-specific navigation
- Azure networking and database domains
- a scalable structure for future additions

Examples are grouped by:

- cloud
- architecture domain
- specific pattern
- variant, such as `basic`

---

## 📂 Available Example Groups

- [Azure examples](azure/README.md)
- [OCI examples](oci/README.md)
- [Multicloud examples availability note](multicloud/README.md)

---

## 🧠 How To Read This Structure

The shared implementation lives under `patterns/`, while `examples/` contains the payloads and thin wrappers that exercise those patterns.

That separation keeps:

- pattern HCL reusable
- payloads easy to compare
- repository growth manageable as more variants are added

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
