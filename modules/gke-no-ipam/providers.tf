terraform {
  required_version = "~> 1.6"

  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}