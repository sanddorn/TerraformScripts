## Dependencies
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~>1.35"
    }
  }
}
# Variables
variable "hcloud_token" {
  type = string
  description = "Token to the Hetzner Cloud API"
}

variable "username" {
  type = string
  description = "User to be provisioned and used for ansible"
  default = "jenkins"
}

variable "server_size" {
  type = string
  description = "Server Sizing"
  default = "cx41"
}

variable "jenkins_path" {
  type = string
  description = "Workdir for agent"
  default = "/opt/jenkins"
}

variable "node_name" {
  type = string
  description = "name of the node"
  default = "jenkins-agent"
}
provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_ssh_keys" "jenkins_master_keys" {
  with_selector = "target=jenkins"
}

data "hcloud_image" "jenkins" {
  with_selector = "jenkins=agent"
}

resource "hcloud_server" "jenkins-slave" {
  name = var.node_name
  image = data.hcloud_image.jenkins.id
  server_type = var.server_size
  location = "nbg1"

//  ssh_keys = data.hcloud_ssh_keys.jenkins_master_keys.ssh_keys.*.name

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "adduser  --disabled-password --gecos \"\" ${var.username}",
      "adduser ${var.username} sudo",
      "mkdir /home/${var.username}/.ssh",
      "touch /home/${var.username}/.ssh/authorized_keys",
      "chown -R ${var.username}:${var.username} /home/${var.username}/.ssh ",
      "chmod 700 /home/${var.username}/.ssh ",
      "chmod 600 /home/${var.username}/.ssh/authorized_keys ",
      "mkdir -p ${var.jenkins_path}",
      "chmod 755 ${var.jenkins_path}",
      "chown ${var.username}:${var.username} ${var.jenkins_path}",
      "adduser ${var.username} docker"
    ]

    connection {
      host = self.ipv4_address
      type = "ssh"
      user = "root"
    }
  }

  provisioner "file" {
    content = "${data.hcloud_ssh_keys.jenkins_master_keys.ssh_keys.0.public_key}"
    destination = "/home/${var.username}/.ssh/authorized_keys"
    connection {
      host = self.ipv4_address
      type = "ssh"
      user = "root"
    }
  }
}

output "instance_ip_addr" {
  value = hcloud_server.jenkins-slave.ipv4_address
}
