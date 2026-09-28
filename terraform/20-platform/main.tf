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
  project                     = var.edge_project_id
  region                      = var.region
  impersonate_service_account = var.tf_admin_service_account
}

provider "google" {
  alias                       = "data"
  project                     = var.data_project_id
  region                      = var.region
  impersonate_service_account = var.tf_admin_service_account
}

resource "google_artifact_registry_repository" "python" {
  project       = var.edge_project_id
  location      = var.region
  repository_id = var.artifact_repository
  description   = "L2Comm Python batch images"
  format        = "DOCKER"
}

resource "google_service_account" "runtime" {
  project      = var.edge_project_id
  account_id   = "sa-l2comm-runtime"
  display_name = "L2Comm GKE Python runtime"
}

resource "google_service_account" "workflow" {
  project      = var.edge_project_id
  account_id   = "sa-l2comm-workflow"
  display_name = "L2Comm Workflow GKE Job launcher"
}

resource "google_service_account" "cloudbuild" {
  project      = var.edge_project_id
  account_id   = "sa-l2comm-cloudbuild"
  display_name = "L2Comm Cloud Build"
}

resource "google_project_iam_member" "runtime_job_user" {
  project = var.edge_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_project_iam_member" "runtime_compute_viewer" {
  project = var.edge_project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_bigquery_dataset_iam_member" "runtime_data_editor" {
  provider   = google.data
  project    = var.data_project_id
  dataset_id = var.target_dataset
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_project_iam_member" "workflow_container_developer" {
  project = var.edge_project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.workflow.email}"
}

resource "google_project_iam_member" "workflow_invoker" {
  project = var.edge_project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.workflow.email}"
}

resource "google_project_iam_member" "cloudbuild_ar_writer" {
  project = var.edge_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_log_writer" {
  project = var.edge_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_storage_viewer" {
  project = var.edge_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_service_account_iam_member" "tf_admin_can_use_cloudbuild" {
  service_account_id = google_service_account.cloudbuild.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.tf_admin_service_account}"
}

resource "google_artifact_registry_repository_iam_member" "gke_node_reader" {
  project    = var.edge_project_id
  location   = var.region
  repository = google_artifact_registry_repository.python.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.vm_service_account}"
}

resource "google_container_cluster" "autopilot" {
  project          = var.edge_project_id
  name             = var.cluster_name
  location         = var.region
  enable_autopilot = true

  network    = "projects/${var.host_project_id}/global/networks/${var.network_name}"
  subnetwork = "projects/${var.host_project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.service_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.control_plane_cidr
  }

  deletion_protection = false
}

output "cluster_name" {
  value = google_container_cluster.autopilot.name
}

output "artifact_image" {
  value = "${var.region}-docker.pkg.dev/${var.edge_project_id}/${var.artifact_repository}/${var.image_name}:${var.image_tag}"
}

output "runtime_service_account" {
  value = google_service_account.runtime.email
}

output "workflow_service_account" {
  value = google_service_account.workflow.email
}
