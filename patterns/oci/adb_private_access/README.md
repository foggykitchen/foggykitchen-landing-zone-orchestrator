# OCI ADB Private Access Pattern

This pattern composes OCI networking, an NSG-protected Autonomous Database private endpoint, and a lightweight validation host into a public reference architecture for **private ADB access**.

It is intentionally scoped to a **single-region private database access** scenario:

- one VCN with a public client subnet and a private ADB subnet
- one NSG attached to the Autonomous Database private endpoint
- one Autonomous Database Serverless deployment with a private endpoint
- one lightweight public compute host used to validate private SQL*Net reachability

It does **not** include:

- cross-region ADB disaster recovery
- File Storage replication
- bastion service integration
- application schema bootstrap or data migration logic

Those richer database platform concerns belong in the private `foggykitchen-landing-zone-blueprint` layer.

## Example

- [`examples/oci/adb/private_access/basic`](../../../../examples/oci/adb/private_access/basic/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
