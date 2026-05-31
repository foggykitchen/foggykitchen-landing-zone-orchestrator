# OCI DevOps Build-Only Pattern

This directory contains the shared **OCI DevOps build-only pattern** used by FoggyKitchen Landing Zone Orchestrator.

---

## 🎯 Purpose

The goal of this pattern is to model a minimal but realistic **OCI DevOps CI flow** through:

- one DevOps project
- one mirrored GitHub repository
- one OCIR repository
- one Docker deploy artifact
- one build pipeline with `BUILD` and `DELIVER_ARTIFACT` stages

---

## ✨ What the pattern does

This pattern composes:

- `terraform-oci-fk-devops`
- `terraform-oci-fk-devops-pipeline`
- `terraform-oci-fk-ocir`

It provisions the shared DevOps control plane and a simple build pipeline, but it intentionally stops before OKE deployment.

The pattern supports a split between:

- `cloud.workload_region` for regional DevOps resources
- `cloud.home_region` for global IAM resources such as policies and dynamic groups

---

## 📂 Consumed By

- [`examples/oci/devops/build_only/basic`](../../../../examples/oci/devops/build_only/basic/README.md)

---

## ⚠️ Scope

This pattern is intentionally **build-only**.

It does not currently add:

- OKE clusters
- deploy environments
- deploy pipelines
- canary or blue-green rollout strategies

Those concerns belong in the next DevOps-oriented patterns.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
