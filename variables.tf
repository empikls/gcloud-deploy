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

variable "database_prod_user_pass" {
  default = "8c7yoI66pd"
}

variable "database_test_user_pass" {
  default = "8c7yoI66pd"
}

variable "kubernetes_ver" {
  default = "1.13.7-gke.8"
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
