terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.7.0"
    }
  }
}

variable "username" {
  type        = string
  description = "ansible user"
  default     = "ansible"
}

variable "ssh_key" {
  type        = string
  description = "ssh key"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDE7CGZhfQoTLR8Bxstotspk+O2Ci5zVPS0LJlTPrys5uwRkjZ2jOhkX4SmWwaBU1olgxkrAFBOFETdQfxssUnTi4hK4MM2PthCUl2xmf8LzPNKj+i3Yud22wmFESDodia13EqXv0XmaLwLkpbO1ERW1E7+qIv63rZcvgIBAUKOjM7GAcM+VVx2NHWjJDylH0vuaLh9ZMam7A4RuPUPAbatz3i/grXmnVAmE8HRhn8GDtQxXo7nMckPpNQIiE9Z6IU5lyEp+jo9wUPnh8QqYlywlxdJg92ZKvr0qMzxcJjRWorPijcnkcQv/rcu23gk6imWZP0FWS6NFgkhNDR7k8hB"
}

variable "ssh_root_key_selector" {
  default = ""
}

variable "do_token" {
  type        = string
  description = "Token to the DO Cloud API"
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "gitea" {
  name = "deploy-key"
}

resource "digitalocean_vpc" "development" {
  name     = "development"
  region   = "fra1"
  ip_range = "10.180.0.0/24"
}

resource "digitalocean_volume" "gitea-data" {
  region                  = "fra1"
  name                    = "gitea-data"
  size                    = 100
  initial_filesystem_type = "ext4"
  description             = "Data partition for gitea"
}

resource "digitalocean_droplet" "gitea_server" {
  image      = "ubuntu-22-10-x64"
  name       = "gitea-server"
  region     = "fra1"
  size       = "s-1vcpu-512mb-10gb"
#  ipv6       = true
  vpc_uuid   = digitalocean_vpc.development.id
  ssh_keys   = [data.digitalocean_ssh_key.gitea.id]
  depends_on = [digitalocean_vpc.development]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "adduser  --disabled-password --gecos \"\" ${var.username}",
      "adduser ${var.username} sudo",
      "mkdir /home/${var.username}/.ssh",
      "echo ${var.ssh_key} >> /home/${var.username}/.ssh/authorized_keys",
      "chown -R ${var.username}:${var.username} /home/${var.username}/.ssh ",
      "chmod 700 /home/${var.username}/.ssh ",
      "chmod 600 /home/${var.username}/.ssh/authorized_keys ",
      "apt -y update",
      "DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade",
    ]

    connection {
      host = self.ipv4_address
      type = "ssh"
      user = "root"
    }
  }

  provisioner "file" {
    destination = "/etc/sudoers"
    source      = "sudoers"

    connection {
      host = self.ipv4_address
      type = "ssh"
      user = "root"
    }
  }
}

resource "digitalocean_volume_attachment" "gitea-data" {
  droplet_id = digitalocean_droplet.gitea_server.id
  volume_id  = digitalocean_volume.gitea-data.id
}

resource "null_resource" "install_gitea" {
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${digitalocean_droplet.gitea_server.ipv4_address},' -e ansible_user=${var.username} main.yml"
  }
  depends_on = [digitalocean_droplet.gitea_server]
}
