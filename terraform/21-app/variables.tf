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

variable "namespace" {
  type    = string
  default = "l2comm-batch"
}

variable "ksa_name" {
  type    = string
  default = "ksa-l2comm-batch"
}

variable "runtime_service_account" {
  type    = string
  default = "sa-l2comm-runtime@gcp-prod-edp-edge-509423.iam.gserviceaccount.com"
}

variable "tf_admin_service_account" {
  type    = string
  default = "sa-l2comm-tf-admin@gcp-prod-edp-edge-509423.iam.gserviceaccount.com"
}
