datacenter = "{{ consul_datacenter }}"

client {
  enabled = true
  network_interface = "{{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"name\" {{ '}}' }}"
  servers = ["{{ groups['consul_server_internal'] | join(', ') }}"]
}

acl {
  enabled = true
}

data_dir  = "/opt/nomad/"
log_file = "/var/log/nomad/"

plugin "docker" {
  config {
    endpoint = "unix:///var/run/docker.sock"

    auth {
      config = "/etc/docker/docker-auth.json"
      helper = "pass"
    }

    extra_labels = ["job_name", "job_id", "task_group_name", "task_name", "namespace", "node_name", "node_id"]

    gc {
      image       = true
      image_delay = "3m"
      container   = true

      dangling_containers {
        enabled        = true
        dry_run        = false
        period         = "5m"
        creation_grace = "5m"
      }
    }

    volumes {
      enabled      = true
      selinuxlabel = "z"
    }

    allow_privileged = false
    allow_caps       = ["chown", "net_raw"]
  }
}
