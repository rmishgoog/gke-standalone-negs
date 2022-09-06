variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}
variable "global_ip_name" {
  default = "global-static-ip-for-negs"
}
variable "forwarding_rule_name" {
  default = "global-neg-gke-lb"
}
variable "target_proxy_name" {
  default = "global-neg-gke-target-proxy"
}
variable "url_map_name" {
  default = "global-neg-based-gke-lb"
}
variable "project" {

}
variable "storage_bucket_name" {
  default = "global-neg-gke-bucket"
}
variable "health_check_name" {
  default = "global-neg-gke-health-checks"
}
variable "health_check_firewall_rule_name" {
  default = "gke-neg-allow-health-check"
}
variable "gke_nodes_target_tags" {
}
variable "gke_neg_backend_name" {
  default = "gke-neg-backend-service"
}
variable "gke_zonal_network_endpoint_group_name" {
}
variable "vpc_network_name" {
  default = "neg-toolkit-vpc"
}
variable "zonal_neg_central_a" {
  default = "us-central1-a"
}
variable "zonal_neg_central_c" {
  default = "us-central1-c"
}
variable "zonal_neg_central_f" {
  default = "us-central1-f"
}
variable "health_check_port" {
  default = 8080
}