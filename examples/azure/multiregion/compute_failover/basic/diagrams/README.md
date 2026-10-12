# Diagrams

This directory is reserved for architecture and validation screenshots captured after a manual apply.

Suggested files:

- `azure_multiregion_compute_failover_basic_architecture.jpg` - architecture diagram
- `azure_multiregion_compute_failover_basic_resource_group.jpg` - deployed Resource Group overview
- `azure_multiregion_compute_failover_basic_frontdoor_overview.jpg` - Azure Front Door profile overview
- `azure_multiregion_compute_failover_basic_frontdoor_origins.jpg` - Azure Front Door origin group with primary and standby origins
- `azure_multiregion_compute_failover_basic_frontdoor_route.jpg` - Azure Front Door route to the origin group
- `azure_multiregion_compute_failover_basic_frontdoor_endpoint_primary.jpg` - Front Door endpoint serving the primary site
- `azure_multiregion_compute_failover_basic_frontdoor_endpoint_failover.jpg` - Front Door endpoint serving the standby site after primary origin failure
- `azure_multiregion_compute_failover_basic_primary_load_balancer_frontend.jpg` - primary regional Load Balancer frontend public IP
- `azure_multiregion_compute_failover_basic_primary_load_balancer_backend.jpg` - primary regional Load Balancer backend pool
- `azure_multiregion_compute_failover_basic_standby_load_balancer_frontend.jpg` - standby regional Load Balancer frontend public IP
- `azure_multiregion_compute_failover_basic_standby_load_balancer_backend.jpg` - standby regional Load Balancer backend pool
- `azure_multiregion_compute_failover_basic_primary_vmss.jpg` - primary VM Scale Set capacity
- `azure_multiregion_compute_failover_basic_standby_vmss.jpg` - standby VM Scale Set warm-standby capacity
- `azure_multiregion_compute_failover_basic_primary_vnet_subnets.jpg` - primary VNet app subnet
- `azure_multiregion_compute_failover_basic_standby_vnet_subnets.jpg` - standby VNet app subnet
- `azure_multiregion_compute_failover_basic_primary_nat_gateway.jpg` - primary NAT Gateway association
- `azure_multiregion_compute_failover_basic_standby_nat_gateway.jpg` - standby NAT Gateway association
