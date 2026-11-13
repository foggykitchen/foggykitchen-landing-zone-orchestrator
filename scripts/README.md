# Scripts

Run `python3 scripts/check-module-refs.py` to reject floating OCI module branch references in source, documentation and payloads. The same check runs in GitHub Actions.

---

## 🎯 Purpose

The goal of this directory is to keep auxiliary automation separate from the shared Terraform / OpenTofu patterns.

Typical future use cases:

- payload validation helpers
- diagram generation helpers
- wrapper utilities for staged deployments
- light documentation tooling

At the current stage, runtime logic stays mostly inside the shared patterns and example-local assets such as `cloud-init` scripts.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
