output "aks" {
  value = module.landing_zone.aks
}

output "acr" {
  value = module.landing_zone.acr
}

output "network" {
  value = module.landing_zone.network
}

output "bastion" {
  value = module.landing_zone.bastion
}

output "jump_host" {
  value = module.landing_zone.jump_host
}

output "devops" {
  value = module.landing_zone.devops
}


output "build_agent" {
  value = module.landing_zone.build_agent
}

output "generated_admin_ssh_private_key_pem" {
  value     = try(tls_private_key.generated[0].private_key_pem, null)
  sensitive = true
}
