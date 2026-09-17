output "aks" {
  value = module.landing_zone.aks
}

output "jump_host" {
  value = module.landing_zone.jump_host
}

output "bastion" {
  value = module.landing_zone.bastion
}

output "acr" {
  value = module.landing_zone.acr
}

output "network" {
  value = module.landing_zone.network
}
