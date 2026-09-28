variable "edge_project_id" {
  type    = string
  default = "gcp-prod-edp-edge-509423"
}

variable "region" {
  type    = string
  default = "asia-northeast3"
}

variable "cluster_name" {
  type    = string
  default = "gke-l2comm-batch-an3"
}

variable "workflow_name" {
  type    = string
  default = "wf-l2comm-gke-job"
}

variable "scheduler_name" {
  type    = string
  default = "sch-l2comm-gke-job"
}

variable "workflow_service_account" {
  type    = string
  default = "sa-l2comm-workflow@gcp-prod-edp-edge-509423.iam.gserviceaccount.com"
}

variable "namespace" {
  type    = string
  default = "l2comm-batch"
}

variable "ksa_name" {
  type    = string
  default = "ksa-l2comm-batch"
}

variable "image_uri" {
  type    = string
  default = "asia-northeast3-docker.pkg.dev/gcp-prod-edp-edge-509423/ar-l2comm-python/python-bq-batch:v1"
}

variable "target_project" {
  type    = string
  default = "pjt-c-admin"
}

variable "target_dataset" {
  type    = string
  default = "dlk_sample"
}

variable "target_table" {
  type    = string
  default = "gcp_public_sample"
}

variable "schedule" {
  type    = string
  default = "0 1 * * *"
}

variable "time_zone" {
  type    = string
  default = "Asia/Seoul"
}
