variable "cluster_name" {
  default = "gke-gevops"
}
variable "project_name" {
  default = "gcpssproject-248009"
}

variable "gloud_creds_file" {
  default = "~/.gcloud/gcpssproject-248009-54dc60693c76.json"
}

variable "storage_creds_file" {
  default = "~/.gcloud/google-storage-admin.json"
}

variable "logicapp_repository" {
  default = "https://github.com/kv-053-devops/logicapp/"
}

variable "location" {
  default = "europe-west1"
}

variable "machine_type" {
//  default = "g1-small"
  default = "n1-standard-1"
}

// Database configuration
variable "database_instance_name" {
  default = "main-postgres"
}

variable "kubernetes_ver" {
  default = "1.13.7-gke.8"
}

variable "logicapp_conf_query_url" {
  default = "http://queryapp.dev.svc:5003/query/yml_data"
}

resource "random_id" "username" {
  byte_length = 14
}

resource "random_id" "password" {
  byte_length = 16
}

resource "random_id" "password_jenkins" {
  byte_length = 24
}
