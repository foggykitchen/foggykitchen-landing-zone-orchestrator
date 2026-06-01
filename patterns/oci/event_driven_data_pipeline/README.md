# OCI Event-Driven Data Pipeline Pattern

This directory contains the shared **OCI event-driven data pipeline** pattern used by FoggyKitchen Landing Zone Orchestrator.

It is based on the architectural flow explored in `lesson7` of `terraform-oci-fk-function`, but expressed here as an orchestrator-level multi-module pattern.

## What It Composes

- one public API Gateway entry point
- one private Functions application with three functions
- one OCI Streaming stream pool and stream
- one OCI Service Connector Hub connector
- one Autonomous Database instance
- explicit IAM for API Gateway, Functions, Streaming, SCH, and ADB access

## Composed Modules

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-api-gateway`
- `terraform-oci-fk-function`
- `terraform-oci-fk-streaming`
- `terraform-oci-fk-sch`
- `terraform-oci-fk-adb`

## Example Consumer

- [`examples/oci/functions/event_driven_data_pipeline/basic`](../../../../examples/oci/functions/event_driven_data_pipeline/basic/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
