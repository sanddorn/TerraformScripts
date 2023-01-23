terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.7.0"
    }
    hetznerdns = {
      source = "timohirt/hetznerdns"
      version = "2.2.0"
    }
  }
}

variable "username" {
  type        = string
  description = "ansible user"
  default     = "ansible"
}


variable "dns_name" {
  type        = string
  description = "dns name"
  default     = "nexus.development.bermuda.de"
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

variable "hetzner_dns_token" {
  type = string
  description = "Hetzner API Token"
}

provider "digitalocean" {
  token = var.do_token
}

provider "hetznerdns" {
  apitoken  = var.hetzner_dns_token
}

data "hetznerdns_zone" "bermuda_zone" {
  name = "bermuda.de"
}

data "digitalocean_ssh_key" "nexus" {
  name = "deploy-key"
}

data "digitalocean_vpc" "vpc" {
  name = "development"
}

resource "digitalocean_vpc" "development" {
  name     = "development"
  region   = "fra1"
  ip_range = "10.180.0.0/24"
  count = data.digitalocean_vpc.vpc.id == null ? 1 : 0
}


resource "digitalocean_droplet" "nexus_server" {
  image      = "ubuntu-22-10-x64"
  name       = "nexus-server"
  region     = "fra1"
  size       = "s-2vcpu-4gb"
#  ipv6       = true
  vpc_uuid   = data.digitalocean_vpc.vpc.id == null ? digitalocean_vpc.development.0.id : data.digitalocean_vpc.vpc.id
  ssh_keys   = [data.digitalocean_ssh_key.nexus.id]
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

resource "hetznerdns_record" "nexus" {
  zone_id = data.hetznerdns_zone.bermuda_zone.id
  name    = "${var.dns_name}."
  type    = "A"
  ttl     = 60
  value   = digitalocean_droplet.nexus_server.ipv4_address
}

resource "null_resource" "install_nexus" {
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${digitalocean_droplet.nexus_server.ipv4_address},' -e nexus_base_name=${var.dns_name} -e ansible_user=${var.username} main.yml"
  }
  depends_on = [digitalocean_droplet.nexus_server]
}
