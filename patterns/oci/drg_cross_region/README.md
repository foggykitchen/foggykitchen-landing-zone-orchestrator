# OCI DRG Cross-Region Pattern

This directory contains the shared **OCI cross-region DRG remote peering pattern** used by FoggyKitchen Landing Zone Orchestrator.

---

## 🎯 Purpose

The goal of this pattern is to model **OCI-native cross-region connectivity** through:

- one DRG per region
- one VCN per region
- one RPC per region
- explicit VCN-side and DRG-side route tables

---

## ✨ What the pattern does

This pattern composes:

- a home-region VCN
- a peer-region VCN
- a home-region DRG
- a peer-region DRG
- one VCN attachment on each DRG
- one RPC on each DRG
- DRG route tables for traffic entering from the VCN and from the RPC
- VCN route tables that send cross-region traffic to the local DRG

---

## 📂 Consumed By

- [`examples/oci/networking/drg_cross_region/basic`](../../../../examples/oci/networking/drg_cross_region/basic/README.md)

---

## ⚠️ Scope

This pattern is intentionally connectivity-first.

It does not currently add:

- compute workloads
- load balancers
- higher-level service integrations

The focus is the DRG + RPC routing model itself.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
