provider "google" {
  credentials = "${file(var.gloud_creds_file)}"
  project     = "${var.project_name}"
  region      = "${var.location}"
}

resource "google_container_cluster" "primary" {
  name        = "${var.cluster_name}"
  project     = "${var.project_name}"
  description = "Demo GKE Cluster"
  location    = "${var.location}-b"
  min_master_version = "${var.kubernetes_ver}"

  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = "${random_id.username.hex}"
    password = "${random_id.password.hex}"
  }
}

resource "google_container_node_pool" "primary" {
  name       = "${var.cluster_name}-node-pool"
  project     = "${var.project_name}"
  location   = "${var.location}-b"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 3

  node_config {
    preemptible  = true
    machine_type = "${var.machine_type}"

    metadata = {
      disable-legacy-endpoints = "true"
    }

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
  cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  username = "${random_id.username.hex}"
  password = "${random_id.password.hex}"
  
}

data "template_file" "kubeconfig" {
  template = file("templates/kubeconfig-template.yaml")

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

data "template_file" "spinnaker_chart" {
  template = file("templates/spinnaker-chart-template.yaml")

  vars = {
    google_project_name = "${var.project_name}"
    google_spin_bucket_name = "${google_storage_bucket.spinnaker-store.name}"
    google_subscription_name = "${google_pubsub_subscription.spinnaker_pubsub_subscription.name}"
    google_spin_sa_key = "${base64decode(google_service_account_key.spinnaker-store-sa-key.private_key)}"

  }
}

resource "local_file" "kubeconfig" {
  content  = data.template_file.kubeconfig.rendered
  filename = "kubeconfig"
}

resource "local_file" "spinnaker_chart" {
  content  = data.template_file.spinnaker_chart.rendered
  filename = "spinnaker-chart.yaml"
}

resource "google_service_account" "spinnaker-store-sa" {
  account_id   = "spinnaker-store-sa-id"
  display_name = "Spinnaker-store-sa"
  # depends_on = ["google_storage_bucket.spinnaker-store"]
}
resource "google_service_account_key" "spinnaker-store-sa-key" {
  service_account_id = "${google_service_account.spinnaker-store-sa.name}"
  public_key_type = "TYPE_X509_PEM_FILE"
}
resource "google_storage_bucket" "spinnaker-store" {
  name     = "${var.project_name}-spinnaker-conf"
  location = "EU"
  force_destroy = true
//  lifecycle {
//    prevent_destroy = true
//  }
}

resource "google_storage_bucket_iam_binding" "spinnaker-bucket-iam" {
  bucket = "${google_storage_bucket.spinnaker-store.name}"
  role        = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.spinnaker-store-sa.email}",
  ]
}

//resource "google_cloudbuild_trigger" "logicapp-trigger" {
//  trigger_template {
//    branch_name = "master"
//    repo_name   = "github_kv-053-devops_logicapp"
//  }
//  description = "Trigger Git repository github_kv-053-devops_logicapp"
//  filename = "cloudbuild.yaml"
//}

resource "google_pubsub_subscription" "spinnaker_pubsub_subscription" {
  name  = "spinnaker-subscription"
  topic = "projects/${var.project_name}/topics/cloud-builds"

  message_retention_duration = "604800s"
  ack_deadline_seconds = 20
  expiration_policy {
    ttl = "2592000s"
  }

}

resource "google_pubsub_subscription_iam_binding" "spinnaker_pubsub_iam_read" {
  subscription = "${google_pubsub_subscription.spinnaker_pubsub_subscription.name}"
  role         = "roles/pubsub.subscriber"
  members      = [
    "serviceAccount:${google_service_account.spinnaker-store-sa.email}",
  ]
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

resource "kubernetes_namespace" "spinnaker" {
  metadata {
    name = "spinnaker"
  }
  depends_on = ["google_container_node_pool.primary"]
}

resource "kubernetes_config_map" "logicapp-env-conf" {
  metadata {
    name = "logicapp-env-vars"
    namespace = "dev"
  }

  data = {
    logicapp-app-query-url = "${var.logicapp_conf_query_url}"
  }
  depends_on = ["kubernetes_namespace.dev"]
}

resource "null_resource" "configure_tiller_spinnaker" {
  provisioner "local-exec" {
    command = <<LOCAL_EXEC
kubectl config use-context ${var.cluster_name} --kubeconfig=${local_file.kubeconfig.filename}
kubectl apply -f create-helm-service-account.yml --kubeconfig=${local_file.kubeconfig.filename}
helm init --service-account helm --upgrade --wait --kubeconfig=${local_file.kubeconfig.filename}
helm install -n spin stable/spinnaker --namespace spinnaker -f ${local_file.spinnaker_chart.filename} --timeout 600 --version 1.8.1 --wait --kubeconfig=${local_file.kubeconfig.filename}
LOCAL_EXEC
  }
  depends_on = ["google_container_node_pool.primary","local_file.kubeconfig","kubernetes_namespace.spinnaker","local_file.spinnaker_chart","google_storage_bucket_iam_binding.spinnaker-bucket-iam","google_pubsub_subscription_iam_binding.spinnaker_pubsub_iam_read"]
}
