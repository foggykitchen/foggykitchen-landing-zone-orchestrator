# Changelog

## v2.0.0 — 2026-11-13

- **BREAKING:** OCI patterns and examples require `oracle/oci >= 9.12.1, < 10.0.0` and OpenTofu `>= 1.11.0`; OCI 6 is no longer supported.
- Pin all 19 composed OCI modules to compatible releases, including Compute v0.3.0, DNS Steering v0.2.0, ADB v2.0.0 and Functions v2.0.0. Replace floating OCI module references with release tags.
- Preserve ADB and Functions inputs and sensitive wallet outputs; expose only the ADB private endpoint IP in the diagnostic command.
- Add plan-only mocked tests for all nine OCI examples, module-reference CI, and payload compatibility metadata.
- Migration: run `tofu init -upgrade` in each OCI root and review `tofu plan` before applying.

See [migration details and validation results](docs/oci-provider-9-migration.md). BaseDB work is excluded from this release change.
