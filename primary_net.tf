module "primary" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"

  network_name = "primary-net"
  routing_mode = "GLOBAL"
  project_id   = var.project_id

  subnets = [
    {
      subnet_name           = "${var.region}-snet1"
      subnet_ip             = "10.48.0.0/24"
      subnet_region         = var.region
      subnet_private_access = "true"
    }
  ]

  firewall_rules = [
    {
      name      = "iap-fw"
      direction = "INGRESS"
      allow = [
        {
          protocol = "TCP"
          ports    = ["22"]
        }
      ]
      ranges = ["35.235.240.0/20"]
    }
  ]
}

module "router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0"
  name    = "primary-router"
  project = var.project_id
  network = module.primary.network_name
  region  = var.region

  nats = [{
    name                               = "primary-nat"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  }]
}
