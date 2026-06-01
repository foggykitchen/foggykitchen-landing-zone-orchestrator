# OCI Authenticated Serverless API Pattern

This shared pattern composes a lightweight, public **authenticated serverless API** on Oracle Cloud Infrastructure.

It focuses on:

- public API Gateway ingress
- private OCI Functions runtime
- custom authentication through a dedicated auth function
- a simple backend function behind the protected route

The pattern is intentionally small and fast to validate. It is meant to complement the heavier OCI Functions patterns already present in the orchestrator.

## Composed Modules

- `terraform-oci-fk-vcn`
- `terraform-oci-fk-policy`
- `terraform-oci-fk-function`
- `terraform-oci-fk-api-gateway`

## Runtime Flow

1. A client sends a request to API Gateway.
2. API Gateway invokes `fnjwtauth` using custom authentication.
3. If the token is valid, API Gateway forwards the request to `fnbackend`.
4. The backend function returns a protected JSON response.

## Notes

- This pattern is intentionally access-focused and does not include ADB, Streaming, SCH, or Object Storage.
- The authentication token is a simple shared secret token carried in the configured request header.

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
