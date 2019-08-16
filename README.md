# Description
Terrafrom GKE cluster, Postgres DB installation
## Requirements 
* Use terrafrom v0.12.6 version minimum
* Use kubectl v1.15.1 version minimum
* Use helm v2.14.3 version minimum
* Configuration variables can be changed in files:
  ```shell
  variables.tf
  ```
## How to run
* Create Google service accout for terraform
* Set variables in variables.tf :
  ```
  project_name - GCP project name
  gloud_creds_file - GCP json service account path
  ```
* Run:
  ```
  terraform init
  terraform apply
  ```
