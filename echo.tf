output "endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}

output "master_version" {
  value = "${google_container_cluster.primary.master_version}"
}

output "k8_client_cert" {
  value = "${google_container_cluster.primary.master_auth.0.client_certificate}"
}

output "k8_client_key" {
  value = "${google_container_cluster.primary.master_auth.0.client_key}"
}

output "k8_ca_cert" {
  value = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}


