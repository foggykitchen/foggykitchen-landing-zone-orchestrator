# Diagrams

This directory is reserved for architecture and validation screenshots captured after a manual `tofu apply`.

Suggested files:

- `azure_bulk_ingestion_pipeline_basic_architecture.jpg` - architecture diagram
- `azure_bulk_ingestion_pipeline_basic_resource_group.jpg` - deployed Resource Group overview
- `azure_bulk_ingestion_pipeline_basic_vnet_subnets.jpg` - VNet subnets for Functions and PostgreSQL
- `azure_bulk_ingestion_pipeline_basic_nsg.jpg` - NSG associated with the Functions integration subnet
- `azure_bulk_ingestion_pipeline_basic_function_app_overview.jpg` - Function App overview
- `azure_bulk_ingestion_pipeline_basic_api_management_operations.jpg` - API Management operation for validation-only `GET /validate`
- `azure_bulk_ingestion_pipeline_basic_storage_container.jpg` - private Blob Storage ingestion container
- `azure_bulk_ingestion_pipeline_basic_event_grid_subscription.jpg` - Event Grid System Topic and Blob Created subscription
- `azure_bulk_ingestion_pipeline_basic_event_hub_overview.jpg` - Event Hub namespace and `ingestion` Event Hub
- `azure_bulk_ingestion_pipeline_basic_postgresql_networking.jpg` - PostgreSQL Flexible Server networking with public access disabled
- `azure_bulk_ingestion_pipeline_basic_private_dns_zone.jpg` - PostgreSQL private DNS zone linked to the VNet
