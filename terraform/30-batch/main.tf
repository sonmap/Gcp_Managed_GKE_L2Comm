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
  project = var.edge_project_id
  region  = var.region
}

resource "google_workflows_workflow" "gke_batch" {
  project         = var.edge_project_id
  region          = var.region
  name            = var.workflow_name
  description     = "Create and wait for the L2Comm Kubernetes Job on GKE Autopilot"
  service_account = var.workflow_service_account

  source_contents = templatefile("${path.module}/workflow.yaml.tftpl", {
    edge_project_id = var.edge_project_id
    region          = var.region
    cluster_name    = var.cluster_name
    namespace       = var.namespace
    ksa_name        = var.ksa_name
    image_uri       = var.image_uri
    target_project  = var.target_project
    target_dataset  = var.target_dataset
    target_table    = var.target_table
  })
}

resource "google_cloud_scheduler_job" "batch" {
  project     = var.edge_project_id
  region      = var.region
  name        = var.scheduler_name
  description = "Trigger L2Comm GKE Python batch workflow"
  schedule    = var.schedule
  time_zone   = var.time_zone

  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.edge_project_id}/locations/${var.region}/workflows/${google_workflows_workflow.gke_batch.name}/executions"
    http_method = "POST"

    oauth_token {
      service_account_email = var.workflow_service_account
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode("{}")
  }
}

output "workflow_name" {
  value = google_workflows_workflow.gke_batch.name
}

output "scheduler_name" {
  value = google_cloud_scheduler_job.batch.name
}
