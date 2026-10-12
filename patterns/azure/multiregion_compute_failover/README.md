# Azure Multiregion Compute Failover Pattern

This directory contains the shared **Azure multiregion_compute_failover** pattern used by FoggyKitchen Landing Zone Orchestrator.

It is the Azure counterpart to the OCI `multiregion_compute_failover` pattern:

- two independent regional Azure stacks
- one VNet per region
- one public Standard Load Balancer per region
- one VM Scale Set per region
- Azure Front Door Standard priority-based origin failover across both public load balancer endpoints

## Summary

This public pattern focuses on stateless cross-region failover for a minimal web workload.

It deliberately excludes:

- file replication
- database replication
- cross-region VNet peering or VPN Gateway
- private Azure Front Door origins through Private Link
- Azure Front Door WAF policy
- customer-managed keys, diagnostics, governance, and hub-spoke transit

The OCI precedent includes DRG remote peering, but the basic failover path uses OCI DNS Steering over public load balancer endpoints. The DRG path is not load-bearing for the stateless, database-less failover mechanism. The Azure mirror therefore keeps the two regional VNets independent and lets Azure Front Door perform edge-level failover between public origins.

The Azure Front Door WAF module is intentionally not composed in this basic parity port. OCI's basic pattern has no WAF-equivalent layer, so WAF belongs in a later secure or enterprise variant.

## What It Creates

- one Resource Group
- one primary-region VNet with an app subnet
- one standby-region VNet with an app subnet
- subnet-associated NSGs in both regions
- NAT Gateway egress for each private app subnet
- one public IP and public Standard Load Balancer per region
- one VM Scale Set per region, attached to the regional Load Balancer backend pool
- one Azure Front Door Standard profile, endpoint, origin group, two origins, and one route

## Example

- [`examples/azure/multiregion/compute_failover/basic`](../../../examples/azure/multiregion/compute_failover/basic/README.md)

## Deferred Scope

A future enterprise-grade multiregion Azure pattern can add private origins through Front Door Premium and Private Link, regional private networking, PostgreSQL read replicas, WAF, diagnostics, and governance. That richer pattern belongs in the private `foggykitchen-landing-zone-blueprint` tier, not in this public basic pattern.

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
