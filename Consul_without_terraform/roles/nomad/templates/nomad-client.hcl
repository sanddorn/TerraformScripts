datacenter = "{{ consul_datacenter }}"

client {
  enabled = true
  network_interface = "{{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"name\" {{ '}}' }}"
}

acl {
  enabled = true
}

data_dir  = "/opt/nomad/"
log_file = "/var/log/nomad/"
