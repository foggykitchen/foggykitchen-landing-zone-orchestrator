output "adb_private_access" {
  value = module.landing_zone.adb_private_access
}

output "validation_host" {
  value = module.landing_zone.validation_host
}

output "network" {
  value = module.landing_zone.network
}

output "adb_wallet" {
  value     = module.landing_zone.adb_wallet
  sensitive = true
}

output "generated_admin_ssh_private_key_pem" {
  value     = try(tls_private_key.generated[0].private_key_pem, null)
  sensitive = true
}
