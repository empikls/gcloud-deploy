provider "google" {
  credentials = "${file("~/.gcloud/gcpssproject-248009-54dc60693c76.json")}"
  project     = "gcpssproject-248009"
  region      = "europe-west1"
}


variable "name" {
  default = "gke-gevops"
}
variable "project" {
  default = "gcpssproject-248009"
}

variable "location" {
  default = "europe-west1"
}

variable "initial_node_count" {
  default = 1
}

variable "machine_type" {
  default = "g1-small"
//  default = "n1-standard-1"
}
