variable "edge_project_id" {
  type    = string
  default = "gcp-prod-edp-edge-509423"
}

variable "host_project_id" {
  type    = string
  default = "gcp-prod-edp-hub-vpchost"
}

variable "region" {
  type    = string
  default = "asia-northeast3"
}

variable "network_name" {
  type    = string
  default = "vpc-prod-edp-hub"
}

variable "subnet_name" {
  type    = string
  default = "subnet-prod-edp-l2comm-gke-an3"
}

variable "node_cidr" {
  type    = string
  default = "10.254.0.0/28"
}

variable "pod_range_name" {
  type    = string
  default = "pods-prod-edp-l2comm-an3"
}

variable "pod_cidr" {
  type    = string
  default = "10.254.2.0/23"
}

variable "service_range_name" {
  type    = string
  default = "services-prod-edp-l2comm-an3"
}

variable "service_cidr" {
  type    = string
  default = "10.254.4.0/24"
}
