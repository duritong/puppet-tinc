define tinc::vpn::node_keys (
  $ensure = present,
  $netname = 'ring0'
){
  # add ${name} to file /etc/tinc/nets.boot => autostart
  # tinc::base::add_to_nets.boot{"${name}":}

  tinc::vpn::node_key_priv{"${name}": }
  tinc::vpn::node_key_pub{"${name}": }
}

