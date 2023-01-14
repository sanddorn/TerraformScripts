datacenter = "{{ consul_datacenter }}"
domain = "{{ consul_domain }}"
data_dir = "/opt/consul"
encrypt = "{{ consul_symetric_key }}"
ca_file = "/etc/consul.d/ca.pem"
cert_file = "/etc/consul.d/client-{{ inventory_hostname }}.pem"
key_file = "/etc/consul.d/client-{{ inventory_hostname }}.key"
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
retry_join = ["{{ groups['consul_server_internal'] | join(',') }}"]
bind_addr = "{{ '{{' }} GetPrivateInterfaces | include \"network\" \"{{ consul_network }}\" | attr \"address\" {{ '}}' }}"
log_file = "/var/log/consul/"

acl = {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
}

performance {
  raft_multiplier = 1
}


