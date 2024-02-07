resource "google_compute_firewall" "app_fw" {
  name          = "allow-nginx"
  direction     = "INGRESS"
  source_ranges = var.primary_net_cidrs
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  project = var.project_id
  network = module.primary.network_name
}
