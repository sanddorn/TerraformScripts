terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.2"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
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

variable "hcloud_token" {
  type        = string
  description = "Token to the Hetzner Cloud API"
}

variable "hetzner_dns_token" {
  type        = string
  description = "Hetzner API Token"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "hetznerdns" {
  apitoken = var.hetzner_dns_token
}

data "hetznerdns_zone" "bermuda_zone" {
  name = "bermuda.de"
}

data "hcloud_network" "development" {
  name = "jenkins_de"
}

data "hcloud_ssh_keys" "ssh_root_keys" {
  with_selector = var.ssh_root_key_selector
}

resource "hcloud_server" "nexus_server" {
  image       = "ubuntu-22.04"
  name        = "nexus-server"
  location    = "nbg1"
  server_type = "cx21"
  ssh_keys    = data.hcloud_ssh_keys.ssh_root_keys.ssh_keys.*.name

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

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
      host = self.ipv6_address
      type = "ssh"
      user = "root"
    }
  }

  provisioner "file" {
    destination = "/etc/sudoers"
    source      = "sudoers"

    connection {
      host = self.ipv6_address
      type = "ssh"
      user = "root"
    }
  }
}

resource "hetznerdns_record" "nexus" {
  zone_id = data.hetznerdns_zone.bermuda_zone.id
  name    = "${var.dns_name}."
  type    = "AAAA"
  ttl     = 60
  value   = hcloud_server.nexus_server.ipv6_address
}

resource "hetznerdns_record" "nexus4" {
  zone_id = data.hetznerdns_zone.bermuda_zone.id
  name    = "${var.dns_name}."
  type    = "A"
  ttl     = 60
  value   = hcloud_server.nexus_server.ipv4_address
}

resource "null_resource" "install_nexus" {
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${hcloud_server.nexus_server.ipv6_address},' -e nexus_base_name=${var.dns_name} -e nexus_ipv4_address=${hcloud_server.nexus_server.ipv4_address} -e nexus_ipv6_address=${hcloud_server.nexus_server.ipv6_address} -e ansible_user=${var.username} main.yml"
  }
  depends_on = [hcloud_server.nexus_server]
}
