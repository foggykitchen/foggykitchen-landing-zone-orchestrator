# Azure AKS Firewall Transit Blueprint

This directory is intentionally kept as a **public placeholder**.

---

## Purpose

The public orchestrator documents that a richer AKS firewall-transit architecture exists, but the implementation itself is distributed separately in the private:

- `foggykitchen-landing-zone-blueprint`

repository.

The public `aks_basic` and `aks_private_acr` examples in this repository are teaser-tier examples. They demonstrate private AKS, Azure Bastion access, NAT Gateway egress, and private ACR access without turning the public orchestrator into the full premium AKS platform blueprint.

---

## Availability

The AKS firewall-transit implementation is **not part of the free public repository**.

It is treated as a premium blueprint because it includes:

- hub-and-spoke AKS network topology
- Azure Firewall transit and inspected egress
- private ACR integration through Private Endpoint
- richer operational validation
- a more opinionated end-to-end platform shape than the public teaser-tier examples

The implementation is available separately in the private:

- [`foggykitchen-landing-zone-blueprint/examples/azure/aks/firewall_transit_basic`](https://github.com/foggykitchen/foggykitchen-landing-zone-blueprint/tree/main/examples/azure/aks/firewall_transit_basic)

repository path. Access to private blueprints, including this AKS firewall-transit implementation, requires a [FoggyKitchen Professional+ subscription](https://foggykitchen.com/membership).

---

## Related Public Examples

Use the public examples in this repository when you need a smaller, single-region learning path:

- [AKS basic](../basic/README.md)
- [AKS private ACR](../private_acr/README.md)

Move to the premium blueprint when you need Azure Firewall transit, hub-and-spoke networking, broader platform governance, or production-grade AKS platform composition.

---

## Need Help

If you want to discuss architecture, implementation, or hands-on delivery support, book a consulting session here:

- https://foggykitchen.com/consulting

---

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
