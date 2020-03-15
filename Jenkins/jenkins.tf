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
variable "jenkins_volume" {
  type = number
  description = "Volume to mount to the server. Must be configured as /var/lib/jenkins."
}

variable "ssh_root_key_selector" {
  type = string
  description = "Selector to ssh root keys"
}

provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_volume" "jenkins_volume" {
  id = var.jenkins_volume
}

data "hcloud_ssh_keys" "ssh_root_keys" {
   with_selector = var.ssh_root_key_selector
}

resource "hcloud_volume_attachment" "jenkins_volume_attachment" {
  volume_id = var.jenkins_volume
  server_id = hcloud_server.jenkins.id
  automount = false
}

resource "hcloud_server" "jenkins" {
  name = "jenkins"
  image = "ubuntu-18.04"
  server_type = "cx11"
  location = "nbg1"

  ssh_keys = ssh_root_keys

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

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${self.ipv4_address},' -e ansible_user=${var.username} install_jenkins.yml"
  }
}

