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
variable "git_volume" {
  default = 0
  type = number
  description = "Volume to mount to the server. Will be mountet as /home/gogs."
}

variable "ssh_root_key_selector" {
  type = string
  description = "Selector to ssh root keys"
}

variable "git_hostname" {
  type = string
  description = "The hostname the git-server shall listen to."
}

variable "gogs_password" {
  type = string
  description = "The password for the mysql database."
}

provider "hcloud" {
  token = var.hcloud_token
}

//data "hcloud_volume" "gogs_volume" {
//  id = var.git_volume
//}

data "hcloud_ssh_keys" "ssh_root_keys" {
  with_selector = var.ssh_root_key_selector
}

resource "hcloud_volume" "gogs_volume" {
  name = "gogs_volume"
  size = 10
  server_id = hcloud_server.gogs.id
  format = "ext4"
  count = var.git_volume == 0 ? 1 : 0

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${hcloud_server.gogs.ipv4_address},' -e ansible_user=${var.username} -e gogs_password=${var.gogs_password} -e git_hostname=${var.git_hostname} install_gogs.yml"
  }

}

resource "hcloud_volume_attachment" "gogs_volume_attachment" {
  volume_id = var.git_volume == 0 ? hcloud_volume.gogs_volume[0].id : var.git_volume
  server_id = hcloud_server.gogs.id
  automount = false
  count = var.git_volume == 0 ? 0 : 1
}

resource "hcloud_server" "gogs" {
  name = "gogs"
  image = "ubuntu-18.04"
  server_type = "cx11"
  location = "nbg1"

  ssh_keys = data.hcloud_ssh_keys.ssh_root_keys.ssh_keys.*.name

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
      host = self.ipv4_address
      type = "ssh"
      user = "root"
    }
  }

  provisioner "file" {
    destination = "/etc/sudoers"
    source = "sudoers"

    connection {
      host = self.ipv4_address
      type = "ssh"
      user = "root"
    }
  }

}

