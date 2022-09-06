#This will be a new project, remember to authenticate gcloud CLI with gcloud auth application-default login.
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

#Enable the required services needed for execution
resource "google_project_service" "enabled_services" {
  project            = var.project
  service            = each.key
  for_each           = toset(["compute.googleapis.com", "container.googleapis.com"])
  disable_on_destroy = false
}

#Create a custom vpc network.
resource "google_compute_network" "custom_vpc_network" {
  project                 = var.project
  name                    = var.vpcnetworkname
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  depends_on = [
    google_project_service.enabled_services
  ]
}

#Create a subnetwork in us-central1 region.
resource "google_compute_subnetwork" "custom_vpc_subnetwork" {
  project                  = var.project
  name                     = var.vpcsubnetworkname
  region                   = var.region
  network                  = google_compute_network.custom_vpc_network.id
  ip_cidr_range            = var.subnetwork_cidr
  private_ip_google_access = true
  depends_on = [
    google_project_service.enabled_services
  ]
}

#Create a custom service account to be used by the nodes in the kubernetes cluster.
resource "google_service_account" "node_service_account" {
  project      = var.project
  account_id   = var.service_account_id
  display_name = "GKE nodes service account"
}

resource "google_project_iam_member" "node_service_account_viewer" {
  project = var.project
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_service_account_metric_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_service_account_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}

resource "google_project_iam_member" "node_service_account_metadata_writer" {
  project = var.project
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.node_service_account.email}"
}

#Create the GKE kubernetes cluster, the master will have a public endpoint with no authorized network.
resource "google_container_cluster" "primary_gke_cluster" {
  project                  = var.project
  name                     = var.clustername
  location                 = var.region
  initial_node_count       = 1
  remove_default_node_pool = true
  network                  = google_compute_network.custom_vpc_network.id
  subnetwork               = google_compute_subnetwork.custom_vpc_subnetwork.id
  networking_mode          = "VPC_NATIVE"
  enable_shielded_nodes    = true
  #The default node pool creation is needed for provisioning (at least 1), then we remove it.
  node_config {
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.pod_cidr
    services_ipv4_cidr_block = var.service_cidr
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }
  addons_config {
    http_load_balancing {
      disabled = false
    }
  }
  depends_on = [
    google_project_service.enabled_services
  ]
}

#Create a node-pool and associate it with the cluster. Just a basic cluster with mostly defaults and no fancy stuff floating around.
resource "google_container_node_pool" "primary_gke_cluster_node_pool" {
  project            = var.project
  name               = "np-${var.clustername}-01"
  cluster            = google_container_cluster.primary_gke_cluster.id
  initial_node_count = var.gke_num_nodes_zone
  node_config {
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    preemptible     = true
    machine_type    = var.machinetype
    service_account = google_service_account.node_service_account.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  node_locations = [ var.zone_central_a, var.zone_central_c, var.zone_central_f ]
}