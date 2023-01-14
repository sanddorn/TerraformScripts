datacenter = "{{ consul_datacenter }}"
server {
  enabled = true
  bootstrap_expect = "{{ groups['consul_server'] | length }}"
}

addresses {
  http = "127.0.0.1 {{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"address\" {{ '}}' }} {{ ansible_default_ipv4.address }}"
  rpc = "{{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"address\" {{ '}}' }}"
  serf = "{{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"address\" {{ '}}' }}"
}
advertise {
  http = "{{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"address\" {{ '}}' }}"
  rpc = "{{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"address\" {{ '}}' }}"
  serf = "{{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"address\" {{ '}}' }}"
}

acl {
  enabled = true
}


data_dir  = "/opt/nomad/"
log_file = "/var/log/nomad/"
