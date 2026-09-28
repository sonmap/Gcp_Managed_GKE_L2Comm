variable "edge_project_id" { type = string, default = "gcp-prod-edp-edge-509423" }
variable "host_project_id" { type = string, default = "gcp-prod-edp-hub-vpchost" }
variable "data_project_id" { type = string, default = "pjt-c-admin" }
variable "region" { type = string, default = "asia-northeast3" }
variable "network_name" { type = string, default = "vpc-prod-edp-hub" }
variable "subnet_name" { type = string, default = "subnet-prod-edp-l2comm-gke-an3" }
variable "pod_range_name" { type = string, default = "pods-prod-edp-l2comm-an3" }
variable "service_range_name" { type = string, default = "services-prod-edp-l2comm-an3" }
variable "control_plane_cidr" { type = string, default = "10.254.5.0/28" }
variable "cluster_name" { type = string, default = "gke-l2comm-batch-an3" }
variable "artifact_repository" { type = string, default = "ar-l2comm-python" }
variable "image_name" { type = string, default = "python-bq-batch" }
variable "image_tag" { type = string, default = "v1" }
variable "tf_admin_service_account" {
  type    = string
  default = "sa-l2comm-tf-admin@gcp-prod-edp-edge-509423.iam.gserviceaccount.com"
}
