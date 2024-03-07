resource "google_service_account" "gke-sa" {
  account_id = "gke-sa-${var.random_suffix}"
}

module "net" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"

  network_name                           = "gke-net-${var.random_suffix}"
  routing_mode                           = "GLOBAL"
  project_id                             = var.project_id
  delete_default_internet_gateway_routes = true

  subnets = [
    {
      subnet_name           = "${var.region}-snet-${var.random_suffix}"
      subnet_ip             = var.subnet_cidr
      subnet_region         = var.region
      subnet_private_access = "true"
    }
  ]

  secondary_ranges = {
    "${var.region}-snet-${var.random_suffix}" = [
      {
        range_name    = "${var.region}-snet-pods-${var.random_suffix}"
        ip_cidr_range = var.secondary_ranges["pods"]
      },
      {
        range_name    = "${var.region}-snet-services-${var.random_suffix}"
        ip_cidr_range = var.secondary_ranges["services"]
      },
    ]
  }

  routes = flatten([
    [for k, v in var.primary_net_cidrs :
      {
        name              = "egress-gke-${k}-${var.random_suffix}"
        description       = "egress through the router for range ${v}"
        destination_range = v
        tags              = "gke-${var.random_suffix}"
        next_hop_instance = google_compute_instance.vm.self_link
        priority          = 100
      }
    ],
    [
      {
        name              = "default-igw-${var.random_suffix}"
        description       = "internet through the router"
        destination_range = "0.0.0.0/0"
        tags              = "gke-${var.random_suffix}"
        next_hop_instance = google_compute_instance.vm.self_link
        priority          = 100
      }
    ]
  ])

  firewall_rules = [
    {
      name      = "iap-fw-${var.random_suffix}"
      direction = "INGRESS"
      allow = [
        {
          protocol = "TCP"
          ports    = ["22"]
        }
      ]
      ranges = ["35.235.240.0/20"]
    },
    {
      name      = "icmp-fw-${var.random_suffix}"
      direction = "INGRESS"
      allow = [
        {
          protocol = "ICMP"
        }
      ]
      ranges = flatten([
        var.subnet_cidr,
        var.secondary_ranges["pods"],
        var.primary_net_cidrs
      ])
    },
    {
      name      = "tcp-primary-fw-${var.random_suffix}"
      direction = "INGRESS"
      allow = [
        {
          protocol = "TCP"
        }
      ]
      ranges = [
        var.subnet_cidr,
        var.secondary_ranges["pods"]
      ]
    },
  ]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version = "~> 30.0"

  depends_on = [google_compute_instance.vm]

  name                                 = "gke-test-${var.random_suffix}"
  project_id                           = var.project_id
  region                               = var.region
  release_channel                      = "RAPID"
  zones                                = var.node_locations
  network                              = module.net.network_name
  subnetwork                           = "${var.region}-snet-${var.random_suffix}"
  ip_range_pods                        = "${var.region}-snet-pods-${var.random_suffix}"
  ip_range_services                    = "${var.region}-snet-services-${var.random_suffix}"
  http_load_balancing                  = true
  horizontal_pod_autoscaling           = true
  enable_private_endpoint              = true
  enable_private_nodes                 = true
  datapath_provider                    = "ADVANCED_DATAPATH"
  monitoring_enable_managed_prometheus = false
  enable_shielded_nodes                = true
  master_global_access_enabled         = false
  master_ipv4_cidr_block               = var.secondary_ranges["master_cidr"]
  master_authorized_networks           = var.master_authorized_networks
  deletion_protection                  = false
  remove_default_node_pool             = true
  disable_default_snat                 = true

  node_pools = [
    {
      name                      = "default-${var.random_suffix}"
      machine_type              = "e2-highcpu-2"
      node_locations            = "${var.region}-b,${var.region}-c"
      min_count                 = 1
      max_count                 = 100
      local_ssd_count           = 0
      spot                      = true
      local_ssd_ephemeral_count = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      logging_variant           = "DEFAULT"
      auto_repair               = true
      auto_upgrade              = true
      service_account           = google_service_account.gke-sa.email
      initial_node_count        = 1
      enable_secure_boot        = true
    },
  ]

  node_pools_tags = {
    all = ["gke-${var.random_suffix}"]
  }

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  timeouts = {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "google_gke_hub_membership" "primary" {
  provider = google-beta

  project       = var.project_id
  membership_id = "${var.project_id}-${module.gke.name}"
  location      = var.region

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke.cluster_id}"
    }
  }
  authority {
    issuer = "https://container.googleapis.com/v1/${module.gke.cluster_id}"
  }
}
