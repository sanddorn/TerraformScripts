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

variable "no_consul_server" {
  type        = number
  description = "Number of consul servers"
  default     = 1
}

variable "no_worker" {
  type        = number
  description = "Number of worker nodes"
  default     = 3
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "consul_dev" {
  name = "deploy-key"
}

resource "digitalocean_vpc" "consul_dev" {
  name     = "consul-dev"
  region   = "fra1"
  ip_range = "10.178.0.0/24"
}

resource "digitalocean_droplet" "consul_server" {
  image      = "ubuntu-22-10-x64"
  name       = "consul-${count.index}"
  region     = "fra1"
  size       = "s-1vcpu-512mb-10gb"
  ipv6       = true
  vpc_uuid   = digitalocean_vpc.consul_dev.id
  ssh_keys   = [data.digitalocean_ssh_key.consul_dev.id]
  count      = var.no_consul_server
  depends_on = [digitalocean_vpc.consul_dev]

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

resource "digitalocean_droplet" "consul_client" {
  image      = "ubuntu-22-10-x64"
  name       = "worker-${count.index}"
  region     = "fra1"
  size       = "s-1vcpu-2gb"
  ipv6       = true
  vpc_uuid   = digitalocean_vpc.consul_dev.id
  ssh_keys   = [data.digitalocean_ssh_key.consul_dev.id]
  count      = var.no_worker
  depends_on = [digitalocean_vpc.consul_dev]

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

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = templatefile("${path.module}/inventory.tmpl", {
    consul_server  = digitalocean_droplet.consul_server.*.ipv4_address
    consul_server_int = digitalocean_droplet.consul_server.*.ipv4_address_private
    consul_client  = digitalocean_droplet.consul_client.*.ipv4_address
    consul_client_int = digitalocean_droplet.consul_client.*.ipv4_address_private
    consul_network = digitalocean_vpc.consul_dev.ip_range
  })

  depends_on = [digitalocean_droplet.consul_server, digitalocean_droplet.consul_client]
}

resource "null_resource" "install_consul" {
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini -e ansible_user=${var.username} consul.yml"
  }
  depends_on = [local_file.ansible_inventory]
}

