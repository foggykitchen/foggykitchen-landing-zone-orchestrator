# OCI BaseDB Private Access Pattern

Compose a single PRIMARY Oracle Base Database VM system, a private OL9 validation host and OCI Bastion Service in an existing compartment. Both subnets prohibit public IPs and Internet ingress. There is no Internet Gateway. NAT provides client HTTPS egress; Oracle Services Network traffic uses Service Gateway.

Use the [basic example](../../../examples/oci/database/basedb/private_access/basic/README.md) and [payload contract](../../../docs/payload-contract.md#oci-basedb-private-access). This pattern requires OpenTofu >= 1.11.0 and OCI provider >= 9.12.1, < 10.0.0.

| Module | Tag | Role |
| --- | --- | --- |
| terraform-oci-fk-vcn | v0.3.0 | Private subnets, minimal custom security lists, NAT and SGW |
| terraform-oci-fk-nsg | v0.2.0 | Client and database security rules |
| terraform-oci-fk-compute | v0.3.0 | Private validation host with Bastion agent plugin |
| terraform-oci-fk-bastion-service | v0.2.0 | Bastion and optional managed SSH session |
| terraform-oci-fk-basedb | v0.2.0 | Single primary DB system, DB Home, database and PDB; optional existing CMK |

`payload_file` and `payload_template_vars` describe topology. Pass `basedb_admin_password` (sensitive) and `admin_ssh_public_key` separately. The YAML contains runtime placeholders; the parser substitutes sentinels, then sends the actual runtime values only to their module inputs. This keeps secrets out of parsed YAML and permits the example's generated SSH key to remain unknown until apply. Exactly one shared SSH key is required.

Both provider slots of BaseDB are mapped: `providers = { oci = oci, oci.target = oci }`. Creation and target database/node reads therefore use the same workload region. BaseDB v0.2.0 automatically emits `db_system_options.storage_management = "LVM"` when `compute_model = "ECPU"`; there is no separate storage-management input.

The Bastion allow list must be nonempty, valid IPv4 CIDRs with nonzero prefixes. The root wrapper also rejects an unrestricted operator CIDR. A 600-second `time_sleep`, keyed by the client instance ID, waits after compute creation before Bastion/session creation. This is a readiness allowance, not a live plugin health check. Session expiry is not a reason to replace the VM; renew the session explicitly when needed.

Network policy is stateful. Database TCP/22 and TCP/1521 ingress comes only from the client subnet. Database HTTPS egress is limited to the regional OSN service CIDR. Client HTTPS egress can use NAT. Both NSGs admit ICMP type 3/code 4 only from the VCN CIDR; external-router PMTUD is not opened globally. The DB security list is empty. The client security list allows only TCP/22 to the client subnet and TCP/1521 to the DB subnet for the service-managed Bastion endpoint, which cannot use the client VM NSG. Both exclude default VCN permissions. Security-list grants are additive to NSGs and apply to every VNIC in the client subnet, so the client also receives these two narrow egress permissions. A dedicated third endpoint subnet would separate that policy but is outside this two-subnet design. Validate the Bastion private endpoint and actual runtime paths before production use.

No schema bootstrap, Data Guard or new compartment is included. The basic example records a live deployment and TCP/1521 check on 2026-11-21, including the observed plugin-readiness and package-installation retries. Same-region and cross-region Data Guard are subsequent orchestrator steps, followed by blueprint compositions. Standard Edition in this baseline is not a Data Guard configuration.

## Optional customer-managed encryption (v2.3.0)

The pattern pins BaseDB **v0.2.0**. Omit `data.basedb.encryption` (the default) to retain Oracle-managed encryption, or supply an **existing** ACTIVE Vault and ENABLED AES-256 key in the workload region. Set `vault_id` and `kms_key_id` together. `kms_key_version_id` is optional and requires that pair; null lets OCI select the current version. A specified version applies to the CDB; OCI generates a version for the PDB.

Configure CMK **when creating the DB system**. The provider marks all three nested database fields ForceNew: adding or changing encryption on an existing system can replace it. These fields are not an in-place migration or rotation workflow. Before upgrading an existing deployment, run `tofu init -upgrade` and review `tofu plan` before any apply. With encryption omitted, no new resources are expected for PRIMARY. Do not add CMK in place to an existing DB system.

### External IAM prerequisites

Have the tenancy/IAM administrator establish effective key access **before provisioning**. This pattern uses an existing compartment and creates no dynamic groups, policies, Vault, key or key versions, and never reads Vault secrets. DB service key access is granted through a dynamic group covering **all DB system nodes**, as required by Oracle; the referenced BaseDB recipe does not use an `Allow service database ...` grant as a substitute.

The following statements preserve the syntax and resource conditions from [BaseDB v0.2.0 example 04 IAM](https://github.com/foggykitchen/terraform-oci-fk-basedb/blob/v0.2.0/examples/04_single_primary_with_cmk/iam.tf). Replace the angle-bracket placeholders with your existing group, compartment, Vault and key OCIDs:

```text
Allow dynamic-group id <db_nodes_dynamic_group_ocid> to use vaults in compartment id <vault_compartment_ocid> where target.vault.id = '<vault_ocid>'
Allow dynamic-group id <db_nodes_dynamic_group_ocid> to manage keys in compartment id <key_compartment_ocid> where target.key.id = '<key_ocid>'
```

The upstream example uses `ALL {resource.compartment.id = '<db_compartment_ocid>'}` for dynamic-group membership in a **dedicated** lab compartment. In a shared existing compartment, have the IAM owner narrow membership to the intended DB nodes; do not grant unrelated workloads access to the key. Vault and key compartments may differ from the DB compartment. Use an existing dedicated database key where possible: `manage keys` permits key-version management and is broader than encrypt/decrypt. The deployment identity separately needs permission to select the Vault/key and create the DB system.

**Without effective IAM, DB system creation fails.** Creating a policy is not proof it has propagated. Verify access with the IAM owner before deployment. See [Oracle BaseDB key prerequisites](https://docs.oracle.com/en/cloud/paas/base-database/guide/key-about.html), [Oracle DB-node key access](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Tasks/assigningkeys.htm) and the [tagged example 04 prerequisites and live evidence](https://github.com/foggykitchen/terraform-oci-fk-basedb/tree/v0.2.0/examples/04_single_primary_with_cmk). The upstream live run is not validation of CMK in this orchestrator composition.

Licensed under the [UPL 1.0](../../../LICENSE).
