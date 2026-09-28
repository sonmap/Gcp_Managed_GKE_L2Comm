terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0, < 8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30, < 3.0"
    }
  }
}

provider "google" {
  project                     = var.edge_project_id
  region                      = var.region
  impersonate_service_account = var.tf_admin_service_account
}

data "google_client_config" "current" {}

data "google_container_cluster" "cluster" {
  project  = var.edge_project_id
  name     = var.cluster_name
  location = var.region
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_namespace_v1" "batch" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account_v1" "runtime" {
  metadata {
    name      = var.ksa_name
    namespace = kubernetes_namespace_v1.batch.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = var.runtime_service_account
    }
  }
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = "projects/${var.edge_project_id}/serviceAccounts/${var.runtime_service_account}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.edge_project_id}.svc.id.goog[${var.namespace}/${var.ksa_name}]"
}

output "namespace" {
  value = kubernetes_namespace_v1.batch.metadata[0].name
}

output "ksa_name" {
  value = kubernetes_service_account_v1.runtime.metadata[0].name
}
