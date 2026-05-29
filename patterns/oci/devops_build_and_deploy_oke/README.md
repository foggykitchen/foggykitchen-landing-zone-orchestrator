# OCI DevOps Build-And-Deploy-OKE Pattern

This directory contains the shared **OCI DevOps build-and-deploy-oke pattern** used by FoggyKitchen Landing Zone Orchestrator.

---

## 🎯 Purpose

The goal of this pattern is to model a public but realistic **OCI DevOps CI/CD flow** through:

- one DevOps project
- two mirrored GitHub repositories
- one OKE cluster
- one build pipeline that builds an image and packages a Helm chart
- one deploy pipeline that is ready to deploy the chart to OKE

---

## ✨ What the pattern does

This pattern composes:

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-oke`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-ocir`
- `terraform-oci-fk-devops`
- `terraform-oci-fk-devops-pipeline`

It extends the public `devops_build_only` pattern with OKE infrastructure, a Helm chart artifact, a DevOps deploy environment, and a Helm deployment stage.

The pattern supports a split between:

- `cloud.workload_region` for regional DevOps, OCIR, OKE, logging, and notifications resources
- `cloud.home_region` for global IAM resources such as policies and dynamic groups

---

## 📂 Consumed By

- [`examples/oci/devops/build_and_deploy_oke/basic`](../../../../examples/oci/devops/build_and_deploy_oke/basic/README.md)

---

## ⚠️ Scope

This public pattern intentionally stays at the **basic OKE deployment** level.

It does not currently add:

- automatic build-to-deploy trigger chaining
- canary rollout stages
- blue-green rollout stages
- premium blueprint integrations

Those concerns belong in the premium DevOps patterns.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
