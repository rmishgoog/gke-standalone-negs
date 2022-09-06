variable "gke_num_nodes_zone" {
  default = "1"
}
variable "service_account_id" {
  default = "neg-toolkit-gke-node-sa"
}
variable "clustername" {
  default = "neg-toolkit-gke-cluster"
}
variable "project" {
}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}
variable "vpcnetworkname" {
  default = "neg-toolkit-vpc"
}
variable "vpcsubnetworkname" {
  default = "neg-toolkit-vpc-subnet-01"
}
variable "machinetype" {
  default = "e2-medium"
}
variable "min_node_count" {
  default = 1
}
variable "max_node_count" {
  default = 3
}
variable "pod_cidr" {
  default = "10.32.0.0/14"
}
variable "service_cidr" {
  default = "10.96.0.0/20"
}
variable "subnetwork_cidr" {
  default = "10.100.0.0/24"
}
variable "master_cidr" {
  default = "172.16.0.0/28"
}
variable "zone_central_a" {
  default = "us-central1-a"
}
variable "zone_central_c" {
  default = "us-central1-c"
}
variable "zone_central_f" {
  default = "us-central1-f"
}