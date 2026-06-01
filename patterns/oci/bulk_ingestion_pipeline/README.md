# OCI Bulk Ingestion Pipeline Pattern

This pattern composes a **file-driven ingestion flow** on OCI:

- Object Storage bucket with object events enabled
- OCI Events rule that invokes `fnbulkload`
- OCI Streaming as the asynchronous buffer
- Service Connector Hub delivery into `fncollector`
- Autonomous Database bootstrap and persistence through `fnadbsetup` and `fncollector`

It is derived from the complete runtime flow validated in the Functions training material, but presented here as an orchestrator-friendly, reusable composition.

## Module Composition

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-objectstorage`
- `terraform-oci-fk-event`
- `terraform-oci-fk-function`
- `terraform-oci-fk-streaming`
- `terraform-oci-fk-sch`
- `terraform-oci-fk-adb`

## Runtime Flow

1. `fnadbsetup` bootstraps the database schema.
2. A JSON object is uploaded into the ingestion bucket.
3. OCI Events invokes `fnbulkload`.
4. `fnbulkload` reads the object and publishes one message per record to Streaming.
5. Service Connector Hub invokes `fncollector`.
6. `fncollector` inserts the processed records into Autonomous Database.

## Inputs

- `payload_file`
- `payload_template_vars`

The payload is expected to define:

- tenancy, compartment, and region split
- VCN and subnet CIDRs
- Functions source path and runtime credentials
- Streaming names
- Object Storage bucket name and event rule name
- Autonomous Database credentials

## Outputs

- Object Storage namespace and bucket identifiers
- OCI Streaming identifiers
- Service Connector state
- Events rule details
- Function OCIDs
- Autonomous Database details

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
