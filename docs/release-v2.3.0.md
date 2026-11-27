# v2.3.0 — Draft release notes

Extends the existing OCI BaseDB private-access pattern and basic example with optional customer-managed encryption. No new pattern or example is introduced.

- Pin `terraform-oci-fk-basedb` v0.2.0 (93ca1d5), replacing v0.1.0.
- Add optional `data.basedb.encryption.vault_id`, `kms_key_id` and `kms_key_version_id`. CMK is off by default (Oracle-managed encryption remains enabled); existing Vault/key only, with external IAM prerequisites documented in both READMEs. The Vault and key IDs must be provided together.
- Fix `compatibility.orchestrator` drift from v2.2.0 to v2.3.0 and set `compatibility.modules.basedb` to v0.2.0.
- Preserve the existing compartment, private network and `oci.target` alias. No IAM, Vault, key, secret reads or STANDBY features are added.

## Existing deployments

Run `tofu init -upgrade`, then review `tofu plan` before apply. No new resources are expected for PRIMARY when encryption remains omitted. The upstream OCI resource addresses are unchanged. Adding encryption to an existing DB system forces replacement; do not do it in place. Changes to any of the three encryption fields can replace the DB system and are not an in-place rotation workflow.

Validation is limited to static checks and plan-only provider mocks. No live apply, no-change upgrade plan or destroy was executed for this PR, so it does not prove live in-place upgrade behavior or effective IAM. Existing README screenshots and connectivity results remain historical non-CMK evidence. Upstream example 04 live CMK evidence is linked separately.

This is a draft for review. Tagging and publishing v2.3.0 require separate approval. ADB, other module bumps and same-region Data Guard are outside this change.
