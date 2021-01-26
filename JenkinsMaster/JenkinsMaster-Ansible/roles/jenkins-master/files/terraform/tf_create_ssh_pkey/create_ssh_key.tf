## Dependencies
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~>1.24.0"
    }
  }
}
# Variables
variable "hcloud_token" {
  type = string
  description = "Token to the Hetzner Cloud API"
}

variable "jenkins_ssh_pkey" {
  type = string
  description = "Jenkins ssh key"
}

variable "jenkins_key_name" {
  type = string
  description = "Name for the Jenkins key, must be unique"
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "jenkins-key" {
  name = var.jenkins_key_name
  labels = {"target":"jenkins"}
  public_key = var.jenkins_ssh_pkey
}
