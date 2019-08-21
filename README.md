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
## Before start
* Prepre Jenskins Chart file for Helm. Copy example file to and name it as "jenkins-chart.yaml"
  ```
  cp jenkins-chart-example.yaml jenkins-chart.yaml
  ```
* Set GitHub user name, password in file "jenkins-chart.yaml". Open it, find and change section:
  ```shell
                      <description>githuborg</description>
                    <username>git-hub-user</username>
                    <password>git-hub-password</password>
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
