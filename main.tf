provider "google" {
  credentials = "${file("~/.gcloud/gcpssproject-248009-54dc60693c76.json")}"
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
  location    = "${var.location}"

  remove_default_node_pool = true
  initial_node_count = "${var.initial_node_count}"

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary" {
  name       = "${var.cluster_name}-node-pool"
  project     = "${var.project_name}"
  location   = "${var.location}"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "${var.machine_type}"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
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

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
}

resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

