## Dependencies
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~>1.35"
    }
  }
}
variable "hcloud_token" {
  type = string
  description = "Token to the Hetzner Cloud API"
}
variable "username" {
  type = string
  description = "User to be provisioned and used for ansible"
}
variable "ssh_key_deployment_user" {
  type = string
  description = "SSH public key to provision on the cloud server for the user"
}

variable "ssh_root_key_selector" {
  type = string
  description = "Selector to ssh root keys"
}

provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_ssh_keys" "ssh_root_keys" {
   with_selector = var.ssh_root_key_selector
}

resource "hcloud_network" "jenkins" {
  name     = "jenkins"
  ip_range = "10.0.0.0/24"
  labels = {
    net="jenkins"
  }
}

resource "hcloud_network_subnet" "jenkins_agent" {
  ip_range     = "10.0.0.0/24"
  network_id   = hcloud_network.jenkins.id
  network_zone = "eu-central"
  type         = "cloud"
}

resource "hcloud_primary_ip" "jenkins" {
  name          = "primary_ip_jenkins"
  datacenter    = "nbg1-dc3"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
  labels = {
    "hallo" : "jenkins"
  }
}

resource "null_resource" "configure_Jenkins" {
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${hcloud_server.jenkins.ipv6_address},' -e ansible_user=${var.username} -e jenkins_terraform_api_token=${var.hcloud_token} JenkinsMaster-Ansible/setup-jenkins.yml"
  }
  depends_on = [hcloud_server.jenkins]
}

resource "hcloud_server" "jenkins" {
  name = "jenkins"
  image = "ubuntu-22.04"
  server_type = "cx11"
  location = "nbg1"

  public_net {
    ipv4_enabled = true
    ipv4 = hcloud_primary_ip.jenkins.id
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.jenkins.id
  }

  ssh_keys = data.hcloud_ssh_keys.ssh_root_keys.ssh_keys.*.name

  depends_on = [
    hcloud_network.jenkins
  ]

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "adduser  --disabled-password --gecos \"\" ${var.username}",
      "adduser ${var.username} sudo",
      "mkdir /home/${var.username}/.ssh",
      "echo ${var.ssh_key_deployment_user} >> /home/${var.username}/.ssh/authorized_keys",
      "chown -R ${var.username}:${var.username} /home/${var.username}/.ssh ",
      "chmod 700 /home/${var.username}/.ssh ",
      "chmod 600 /home/${var.username}/.ssh/authorized_keys ",
    ]

    connection {
      host = self.ipv6_address
      type = "ssh"
      user = "root"
    }
  }

  provisioner "file" {
    destination = "/etc/sudoers"
    source = "sudoers"

    connection {
      host = self.ipv6_address
      type = "ssh"
      user = "root"
    }
  }
}

