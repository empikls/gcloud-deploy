provider "google" {
  credentials = "${file(var.gloud_creds_file)}"
  project     = "${var.project_name}"
  region      = "${var.location}"
}

#resource "google_sql_database_instance" "postgres" {
#  name = "${var.database_instance_name}"
#  database_version = "POSTGRES_9_6"
#  settings {
#    tier = "db-f1-micro"
#  }
#}
#
#
#resource "google_sql_database" "database-prod" {
#  name      = "prod-db"
#  instance  = "${google_sql_database_instance.postgres.name}"
#}
#
#resource "google_sql_database" "database-test" {
#  name      = "test-db"
#  instance  = "${google_sql_database_instance.postgres.name}"
#}
#
#resource "google_sql_user" "users-prod" {
#  name     = "postgres"
#  instance = "${google_sql_database_instance.postgres.name}"
#  password = "${var.database_prod_user_pass}"
#}
#
#resource "google_sql_user" "users-test" {
#  name     = "postgres-test"
#  instance = "${google_sql_database_instance.postgres.name}"
#  password = "${var.database_test_user_pass}"
#}

resource "google_container_cluster" "primary" {
  name        = "${var.cluster_name}"
  project     = "${var.project_name}"
  description = "Demo GKE Cluster"
  location    = "${var.location}-b"

  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = "wax1DLtRu8"
    password = "z6Gv5L4Rwb7H42zX"

//    client_certificate_config {
////      issue_client_certificate = true
//      issue_client_certificate = false
//    }
  }
}

resource "google_container_node_pool" "primary" {
  name       = "${var.cluster_name}-node-pool"
  project     = "${var.project_name}"
  location   = "${var.location}-b"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "${var.machine_type}"

//    metadata = {
//      disable-legacy-endpoints = "true"
//    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}


provider "kubernetes" {
  host = "https://${google_container_cluster.primary.endpoint}"
  client_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.client_certificate)}"
  client_key = "${base64decode(google_container_cluster.primary.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
}

data "template_file" "kubeconfig" {
  template = file("kubeconfig-template.yaml")

  vars = {
    cluster_name    = google_container_cluster.primary.name
    user_name       = google_container_cluster.primary.master_auth[0].username
    user_password   = google_container_cluster.primary.master_auth[0].password
    endpoint        = google_container_cluster.primary.endpoint
    cluster_ca      = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
    client_cert     = google_container_cluster.primary.master_auth[0].client_certificate
    client_cert_key = google_container_cluster.primary.master_auth[0].client_key
  }
}

resource "local_file" "kubeconfig" {
  content  = data.template_file.kubeconfig.rendered
  filename = "kubeconfig"
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
  depends_on = ["google_container_node_pool.primary"]
}

resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
  depends_on = ["google_container_node_pool.primary"]
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
  depends_on = ["google_container_node_pool.primary"]
}

