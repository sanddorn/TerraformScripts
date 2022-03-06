datacenter = "{{ consul_datacenter }}"
server {
  enabled = true
  bootstrap_expect = {{ groups['consul_server'] | length }}
}

acl {
  enabled = true
}


data_dir  = "/opt/nomad/"
log_file = "/var/log/nomad/"
