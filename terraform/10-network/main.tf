terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0, < 8.0"
    }
  }
}

provider "google" {
  project                     = var.host_project_id
  region                      = var.region
  impersonate_service_account = var.tf_admin_service_account
}

data "google_compute_network" "shared_vpc" {
  project = var.host_project_id
  name    = var.network_name
}

data "google_project" "service_project" {
  project_id = var.edge_project_id
}

resource "google_compute_shared_vpc_service_project" "edge" {
  host_project    = var.host_project_id
  service_project = var.edge_project_id
}

resource "google_compute_subnetwork" "gke" {
  project                  = var.host_project_id
  name                     = var.subnet_name
  region                   = var.region
  network                  = data.google_compute_network.shared_vpc.id
  ip_cidr_range            = var.node_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pod_range_name
    ip_cidr_range = var.pod_cidr
  }

  secondary_ip_range {
    range_name    = var.service_range_name
    ip_cidr_range = var.service_cidr
  }

  depends_on = [google_compute_shared_vpc_service_project.edge]
}

locals {
  project_number    = data.google_project.service_project.number
  gke_service_agent = "service-${local.project_number}@container-engine-robot.iam.gserviceaccount.com"
  cloud_services_sa = "${local.project_number}@cloudservices.gserviceaccount.com"
}

resource "google_compute_subnetwork_iam_member" "gke_agent_network_user" {
  project    = var.host_project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.gke.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${local.gke_service_agent}"
}

resource "google_compute_subnetwork_iam_member" "cloud_services_network_user" {
  project    = var.host_project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.gke.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${local.cloud_services_sa}"
}

resource "google_project_iam_member" "gke_host_service_agent_user" {
  project = var.host_project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:${local.gke_service_agent}"
}

resource "google_project_iam_member" "gke_firewall_admin" {
  project = var.host_project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${local.gke_service_agent}"
}
