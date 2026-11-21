locals {
  # Keep the topology plan-known even when TLS generates the key during apply.
  # Real passwords never pass through templatefile/yamldecode.
  config = yamldecode(templatefile(var.payload_file, merge(var.payload_template_vars, {
    basedb_admin_password = "__runtime_password__"
    admin_ssh_public_key  = "__runtime_public_key__"
  })))
  landing_zone = local.config.landing_zone
  cloud        = local.config.cloud
  network      = try(local.config.architecture.network, {})
  client       = try(local.config.workload.client, {})
  basedb       = local.config.data.basedb
  bastion      = local.config.access.bastion

  project_name       = try(local.landing_zone.name, "fk-oci-basedb-private-access-dev")
  tenancy_ocid       = local.cloud.tenancy_ocid
  compartment_ocid   = local.cloud.compartment_ocid
  defined_tags       = try(local.landing_zone.defined_tags, {})
  freeform_tags      = try(local.landing_zone.freeform_tags, {})
  vcn_cidr           = try(local.network.vcn_cidr, "10.130.0.0/16")
  client_subnet_cidr = try(local.network.client_subnet_cidr, "10.130.10.0/24")
  db_subnet_cidr     = try(local.network.db_subnet_cidr, "10.130.20.0/24")
  availability_domain = coalesce(try(local.basedb.availability_domain, null),
  data.oci_identity_availability_domains.this.availability_domains[0].name)

  client_name             = try(local.client.name, "${local.project_name}-client")
  client_assign_public_ip = false
  client_ssh_keys = [for key in local.client.ssh_authorized_keys :
    key == "__runtime_public_key__" ? trimspace(var.admin_ssh_public_key) : trimspace(key)
  ]
  bastion_allow_list     = local.bastion.client_cidr_allow_list
  bastion_create_session = try(local.bastion.create_session, true)
  bastion_session_ttl    = try(local.bastion.session_ttl_in_seconds, 3600)

  subnets = {
    client_private = {
      cidr_block                    = local.client_subnet_cidr
      display_name                  = "${local.project_name}-client-private"
      dns_label                     = "client"
      route_table_key               = "private"
      security_list_keys            = ["bastion_endpoint"]
      include_default_security_list = false
      prohibit_public_ip_on_vnic    = true
      prohibit_internet_ingress     = true
    }
    db_private = {
      cidr_block                    = local.db_subnet_cidr
      display_name                  = "${local.project_name}-db-private"
      dns_label                     = "database"
      route_table_key               = "private"
      security_list_keys            = ["nsg_only"]
      include_default_security_list = false
      prohibit_public_ip_on_vnic    = true
      prohibit_internet_ingress     = true
    }
  }
  db_security_rules = [
    { name = "client-sqlnet", direction = "INGRESS", protocol = "6", source = local.client_subnet_cidr, source_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 1521, max = 1521 } } },
    { name = "client-ssh", direction = "INGRESS", protocol = "6", source = local.client_subnet_cidr, source_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 22, max = 22 } } },
    { name = "oci-https", direction = "EGRESS", protocol = "6", destination = data.oci_core_services.osn.services[0].cidr_block, destination_type = "SERVICE_CIDR_BLOCK", tcp_options = { destination_port_range = { min = 443, max = 443 } } },
    { name = "pmtud", direction = "INGRESS", protocol = "1", source = local.vcn_cidr, source_type = "CIDR_BLOCK", icmp_options = { type = 3, code = 4 } }
  ]
  client_security_rules = [
    { name = "bastion-ssh", direction = "INGRESS", protocol = "6", source = local.client_subnet_cidr, source_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 22, max = 22 } } },
    { name = "db-sqlnet", direction = "EGRESS", protocol = "6", destination = local.db_subnet_cidr, destination_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 1521, max = 1521 } } },
    { name = "db-ssh", direction = "EGRESS", protocol = "6", destination = local.db_subnet_cidr, destination_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 22, max = 22 } } },
    { name = "https", direction = "EGRESS", protocol = "6", destination = "0.0.0.0/0", destination_type = "CIDR_BLOCK", tcp_options = { destination_port_range = { min = 443, max = 443 } } },
    { name = "pmtud", direction = "INGRESS", protocol = "1", source = local.vcn_cidr, source_type = "CIDR_BLOCK", icmp_options = { type = 3, code = 4 } }
  ]
  default_client_user_data = <<-EOT
    #cloud-config
    packages:
      - nmap-ncat
      - bind-utils
    write_files:
      - path: /opt/fk-basedb-private/README.txt
        owner: root:root
        permissions: "0644"
        content: |
          FoggyKitchen BaseDB private access validation host
          Retrieve the DB private IP from the basedb_private_access output.
          Check: nc -vz <db-private-ip> 1521
          DNS: dig <database-hostname>
          Optional: install Oracle Instant Client SQL*Plus, then connect to the
          PDB service reported in connection_strings. Enter passwords interactively.
          A successful TCP check does not prove SQL authentication.
  EOT
  client_user_data         = base64encode(coalesce(try(local.client.cloud_init_override, null), local.default_client_user_data))
}
