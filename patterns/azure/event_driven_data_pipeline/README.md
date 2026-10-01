# Azure Event-Driven Data Pipeline Pattern

This directory contains the shared **Azure event_driven_data_pipeline** pattern used by FoggyKitchen Landing Zone Orchestrator.

It composes one API-driven ingestion flow:

- API Management publishes one HTTP route to `fninitiator`
- `fninitiator` publishes records into one Event Hub
- `fncollector` consumes the Event Hub through native Azure Functions bindings
- `fncollector` persists records into PostgreSQL Flexible Server over delegated-subnet private access
- validation-only API Management `GET /validate` invokes `fnvalidator` to prove that PostgreSQL contains an expected row

## Summary

This is a public orchestrator pattern for the Azure Functions/event-driven teaser tier.

It deliberately excludes:

- Service Connector Hub or Service Bus equivalents
- hand-authored API Management policy XML
- Blob Storage ingestion, Event Grid, and `fnbulkload` bulk-load handling
- PostgreSQL Entra authentication, customer-managed keys, or diagnostics
- private endpoint variants for the Function App, Storage Account, Event Hub, API Management, or PostgreSQL
- CI/CD or Azure DevOps deployment pipelines
- hub-and-spoke, firewall transit, multi-region, and governance composition

Those richer concerns belong in a future private blueprint layer or later narrowly scoped PRs. Blob Storage and Event Grid ingestion stay in the separate Azure `bulk_ingestion_pipeline` pattern so this API-driven pattern remains aligned with the OCI Functions split.

## What It Creates

- one Resource Group
- one self-contained VNet
- one subnet for Functions regional VNet integration
- one delegated PostgreSQL subnet
- one NSG associated with the Functions integration subnet
- one private DNS zone linked to the VNet for PostgreSQL delegated-subnet private access
- one Storage Account used by the Function App runtime
- one user-assigned managed identity for the Function App
- one Event Hubs namespace with one Event Hub
- RBAC assignments for Event Hub sender/receiver access
- one PostgreSQL Flexible Server with public network access disabled
- one Linux Function App ZIP deployment containing `fninitiator`, `fncollector`, and `fnvalidator`
- one API Management Consumption service with generated routes to `fninitiator` and validation-only `fnvalidator`

## Azure Platform Notes

The pattern follows Azure-native serverless behavior rather than porting OCI resources literally.

- Event Hub-triggered Functions use native Azure Functions trigger bindings. There is no Service Connector Hub resource.
- API Management routing is expressed only through `terraform-az-fk-api-management` `routes`; the module generates operation policy XML internally.
- The current Function module deploys one Function App package. Named functions are defined in the ZIP content, so the pattern uses one module instance containing all runtime functions.
- The current API Management module uses Consumption-tier public APIM, and the current Function module does not expose access restriction or Private Endpoint inputs. The intended public entry point is APIM, while private data access is enforced on PostgreSQL.

## Example

- [`examples/azure/functions/event_driven_data_pipeline/basic`](../../../examples/azure/functions/event_driven_data_pipeline/basic/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
