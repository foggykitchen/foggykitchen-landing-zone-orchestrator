output "aks" {
  value = module.landing_zone.aks
}

output "jump_host" {
  value = module.landing_zone.jump_host
}

output "bastion" {
  value = module.landing_zone.bastion
}

output "network" {
  value = module.landing_zone.network
}
