# OCI BaseDB Examples

This directory contains **OCI Base Database VM system-focused payload examples** organized around access and connectivity patterns.

---

## 🎯 Purpose

The goal of this section is to group OCI BaseDB examples in a way that stays readable as more private access and disaster recovery variants are added.

Current emphasis:

- private single-primary BaseDB access with explicit VCN composition
- OCI Bastion Service and a private validation host for SQL*Net reachability

BaseDB has no Free Tier. The basic example documents live deployment, TCP/1521 validation and cleanup on 2026-11-21. Same-region and cross-region Data Guard will follow separately in the orchestrator, then the blueprint repository.

---

## 📂 Available BaseDB Domains

- [Private access examples](private_access/README.md)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
