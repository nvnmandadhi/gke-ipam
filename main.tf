module "gke-no-ipam-1" {
  source = "./modules/gke-no-ipam"

  project_id                 = var.project_id
  region                     = var.region
  random_suffix              = "98dfd1"
  node_locations             = var.node_locations
  subnet_cidr                = var.subnet_cidr
  secondary_ranges           = var.secondary_ranges
  master_authorized_networks = var.master_authorized_networks
  router_machine_type        = var.router_machine_type
  primary_subnet             = module.primary.subnets_ids[0]
  primary_net_cidrs          = var.primary_net_cidrs
}

module "gke-no-ipam-2" {
  source = "./modules/gke-no-ipam"

  project_id                 = var.project_id
  region                     = var.region
  random_suffix              = "30148c"
  node_locations             = var.node_locations
  subnet_cidr                = var.subnet_cidr
  secondary_ranges           = var.secondary_ranges
  master_authorized_networks = var.master_authorized_networks
  router_machine_type        = var.router_machine_type
  primary_subnet             = module.primary.subnets_ids[0]
  primary_net_cidrs          = var.primary_net_cidrs
}
