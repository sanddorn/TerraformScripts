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

variable "username" {
  type = string
  description = "User to be provisioned and used for ansible"
  default = "jenkins"
}

variable "server_size" {
  type = string
  description = "Server Sizing"
}

variable "jenkins_agent_jar_url" {
  type = string
  description = "URL to get the agent.jar"
}

variable "jenkins_path" {
  type = string
  description = "Workdir for agent"
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

resource "hcloud_server" "jenkins-slave" {
  name = var.node_name
  image = "ubuntu-20.04"
  server_type = var.server_size
  location = "nbg1"

  ssh_keys = data.hcloud_ssh_keys.jenkins_master_keys.ssh_keys.*.name

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "adduser  --disabled-password --gecos \"\" ${var.username}",
      "adduser ${var.username} sudo",
      "mkdir /home/${var.username}/.ssh",
      "echo ${data.hcloud_ssh_keys.jenkins_master_keys.ssh_keys.0.public_key} >> /home/${var.username}/.ssh/authorized_keys",
      "chown -R ${var.username}:${var.username} /home/${var.username}/.ssh ",
      "chmod 700 /home/${var.username}/.ssh ",
      "chmod 600 /home/${var.username}/.ssh/authorized_keys ",
      "apt install -y openjdk-8-jre-headless",
      "mkdir -p ${var.jenkins_path}",
      "chmod 755 ${var.jenkins_path}",
      "chown ${var.username}:${var.username} ${var.jenkins_path}",
      "curl -o ${var.jenkins_path}/agent.jar ${var.jenkins_agent_jar_url}",
      "curl https://download.docker.com/linux/ubuntu/gpg | apt-key add -",
      "curl https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -",
      "apt-add-repository 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main'",
      "apt-add-repository 'deb https://download.docker.com/linux/ubuntu focal stable'",
      "curl https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -",
      "apt-add-repository 'https://aquasecurity.github.io/trivy-repo/deb focal main'",
      "apt update && apt install -y git google-chrome-stable openjdk-8-jre-headless docker-ce docker-ce-cli containerd.io trivy"
    ]

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
