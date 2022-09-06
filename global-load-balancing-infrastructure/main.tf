provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_storage_bucket" "static_content_regional_bucket" {
  name                        = "${var.project}-static"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy = true

}

resource "google_compute_global_address" "global_ip_address" {
  name         = var.global_ip_name
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "global_lb_fwd_rule" {
  name                  = var.forwarding_rule_name
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  ip_address            = google_compute_global_address.global_ip_address.id
  target                = google_compute_target_http_proxy.global_lb_target_proxy.id
}

resource "google_compute_target_http_proxy" "global_lb_target_proxy" {
  name    = var.target_proxy_name
  url_map = google_compute_url_map.global_lb_url_map.id
}

resource "google_compute_url_map" "global_lb_url_map" {
  name            = var.url_map_name
  default_service = google_compute_backend_bucket.gke_neg_poc_storage_bucket.id
  path_matcher {
    default_service = google_compute_backend_service.gke_neg_poc_backend_service.id
    name = "global-lb-service-path-matcher"
    path_rule {
      paths   = ["/service"]
      service = google_compute_backend_service.gke_neg_poc_backend_service.id
    }
  }
  path_matcher {
    default_service = google_compute_backend_bucket.gke_neg_poc_storage_bucket.id
    name = "global-lb-static-path-matcher"
    path_rule {
      paths   = ["/static"]
      service = google_compute_backend_bucket.gke_neg_poc_storage_bucket.id
    }
  }
  host_rule {
    hosts        = ["api.example.com"]
    path_matcher = "global-lb-service-path-matcher"
  }
  host_rule {
    hosts        = ["static.example.com"]
    path_matcher = "global-lb-static-path-matcher"
  }
}

resource "google_compute_backend_bucket" "gke_neg_poc_storage_bucket" {
  name        = var.storage_bucket_name
  bucket_name = google_storage_bucket.static_content_regional_bucket.name
}


resource "google_compute_health_check" "gke_neg_backend_health_check" {
  name               = var.health_check_name
  timeout_sec        = 1
  check_interval_sec = 5
  tcp_health_check {
    port = var.health_check_port
  }
}

resource "google_compute_firewall" "gke_neg_backend_health_check_allow" {
  name    = var.health_check_firewall_rule_name
  network = data.google_compute_network.gke_neg_poc_vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [var.gke_nodes_target_tags]

}

# resource "google_compute_firewall" "gke_neg_backend_lb_pod_allow" {
#   name    = var.health_check_firewall_rule_name
#   network = data.google_compute_network.gke_neg_poc_vpc_network.name
#   allow {
#     protocol = "tcp"
#     ports    = ["80"]
#   }
#   source_ranges = ["130.211.0.0/22","35.191.0.0/16"]
#   target_tags = [ var.gke_nodes_target_tags ]

# }

resource "google_compute_backend_service" "gke_neg_poc_backend_service" {
  name                            = var.gke_neg_backend_name
  enable_cdn                      = false
  timeout_sec                     = 10
  connection_draining_timeout_sec = 10
  health_checks                   = [google_compute_health_check.gke_neg_backend_health_check.id]
  backend {
    balancing_mode        = "RATE"
    max_rate_per_endpoint = 100
    group                 = data.google_compute_network_endpoint_group.gke_zonal_network_endpoint_group_zone_a.id
  }
  backend {
    balancing_mode        = "RATE"
    max_rate_per_endpoint = 100
    group                 = data.google_compute_network_endpoint_group.gke_zonal_network_endpoint_group_zone_c.id
  }
  backend {
    balancing_mode        = "RATE"
    max_rate_per_endpoint = 100
    group                 = data.google_compute_network_endpoint_group.gke_zonal_network_endpoint_group_zone_f.id
  }
}

data "google_compute_network_endpoint_group" "gke_zonal_network_endpoint_group_zone_a" {
  name = var.gke_zonal_network_endpoint_group_name
  zone = var.zonal_neg_central_a
}

data "google_compute_network_endpoint_group" "gke_zonal_network_endpoint_group_zone_c" {
  name = var.gke_zonal_network_endpoint_group_name
  zone = var.zonal_neg_central_c
}

data "google_compute_network_endpoint_group" "gke_zonal_network_endpoint_group_zone_f" {
  name = var.gke_zonal_network_endpoint_group_name
  zone = var.zonal_neg_central_f
}

data "google_compute_network" "gke_neg_poc_vpc_network" {
  name = var.vpc_network_name
}

