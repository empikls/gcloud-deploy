provider "google" {
  credentials = "${file(var.gloud_creds_file)}"
  project     = "${var.project_name}"
  region      = "${var.location}"
}

resource "google_cloudbuild_trigger" "logicapp-trigger" {
  trigger_template {
    branch_name = "master"
    repo_name   = "github_kv-053-devops_logicapp"
  }
  description = "Trigger Git repository ${var.logicapp_repository}" 
  filename = "cloudbuild.yaml"
}

