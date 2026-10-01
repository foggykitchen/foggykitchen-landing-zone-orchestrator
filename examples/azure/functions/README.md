# Azure Functions Examples

This directory contains Azure Functions-oriented landing zone examples for the public FoggyKitchen Landing Zone Orchestrator.

The examples are intentionally split by ingestion style, matching the OCI Functions family:

- API-driven ingestion through API Management belongs to `event_driven_data_pipeline`
- Blob upload ingestion through Event Grid belongs to `bulk_ingestion_pipeline`

## Available Scenarios

| Scenario | Description |
| --- | --- |
| [event_driven_data_pipeline](event_driven_data_pipeline/README.md) | API Management invokes `fninitiator`, Event Hubs buffers messages, `fncollector` writes to PostgreSQL, and `fnvalidator` proves persistence. |
| [bulk_ingestion_pipeline](bulk_ingestion_pipeline/README.md) | Blob Created events invoke `fnbulkload`, Event Hubs buffers messages, `fncollector` writes to PostgreSQL, and `fnvalidator` proves persistence. |

## Scope Boundary

These examples are teaser-tier serverless data patterns. They avoid Service Connector Hub-style resources, hand-authored API Management policy XML, CI/CD, hub-and-spoke, firewall transit, and secure variants with private endpoints for every platform dependency.

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
