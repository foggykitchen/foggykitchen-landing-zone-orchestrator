# OCI Multiregion Compute Failover Pattern

This pattern composes OCI networking, DRG remote peering, compute instance pools, public load balancers, and DNS steering into a lightweight public multiregion failover architecture.

It is intentionally scoped to **stateless failover**:

- primary region with an Instance Pool and public Load Balancer
- standby region with a smaller Instance Pool and public Load Balancer
- cross-region DRG remote peering between both sites
- OCI DNS Steering failover across the two public load balancer endpoints

It does **not** include:

- File Storage replication
- Autonomous Database replication
- application-level data synchronization

Those stateful DR concerns belong in the private `foggykitchen-landing-zone-blueprint` layer.

## Example

- [`examples/oci/multiregion/compute_failover/basic`](../../../../examples/oci/multiregion/compute_failover/basic/README.md)

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
