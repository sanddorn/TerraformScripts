## Dependencies
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~>1.35"
    }
    hetznerdns = {
      source = "timohirt/hetznerdns"
      version = "2.2.0"
    }
  }
}
variable "hcloud_token" {
  type = string
  description = "Token to the Hetzner Cloud API"
}

variable "hetzner_dns_token" {
  type = string
  description = "Token to the Hetzner DNS API"
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

variable "jenkins_dns_name" {
  type        = string
  description = "dns name"
  default     = "jenkins.development.bermuda.de"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "hetznerdns" {
  apitoken  = var.hetzner_dns_token
}

data "hcloud_ssh_keys" "ssh_root_keys" {
   with_selector = var.ssh_root_key_selector
}

data "hetznerdns_zone" "bermuda_zone" {
  name = "bermuda.de"
}

resource "hcloud_network" "jenkins" {
  name     = "jenkins"
  ip_range = "10.0.0.0/24"
  labels = {
    net="jenkins"
  }
}

resource "hcloud_network_subnet" "jenkins_agent" {
  ip_range     = "10.0.0.128/25"
  network_id   = hcloud_network.jenkins.id
  network_zone = "us-east"
  type         = "cloud"
}

resource "hcloud_server" "jenkins" {
  name = "jenkins"
  image = "ubuntu-22.04"
  server_type = "cx11"
  location = "nbg1"

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


resource "null_resource" "configure_Jenkins" {
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${hcloud_server.jenkins.ipv6_address},' -e ansible_user=${var.username} -e web_base_name=${var.jenkins_dns_name} -e jenkins_url=https://${var.jenkins_dns_name}/ -e jenkins_terraform_api_token=${var.hcloud_token} JenkinsMaster-Ansible/setup-jenkins.yml"
  }
  depends_on = [hcloud_server.jenkins]
}

resource "hetznerdns_record" "jenkins" {
  zone_id = data.hetznerdns_zone.bermuda_zone.id
  name    = "${var.jenkins_dns_name}."
  type    = "A"
  ttl     = 60
  value   = hcloud_server.jenkins.ipv4_address
}

resource "hetznerdns_record" "jenkinsAAAA" {
  zone_id = data.hetznerdns_zone.bermuda_zone.id
  name    = "${var.jenkins_dns_name}."
  type    = "AAAA"
  ttl     = 60
  value   = hcloud_server.jenkins.ipv6_address
}

