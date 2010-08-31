define tinc::vpn::node_key_priv(
  $ensure = present,
  $netname = 'ring0',
  $key = ''
){
  # put key into /etc/tinc/${netname}/rsa_key.priv
  file{"/etc/tinc/${netname}/rsa_key.priv":
    ensure => file,
    source => [ "puppet:///modules/site-tinc/keys/$fqdn/rsa_key.priv",
    ]
    owner => root, group => 0, mode => 0644;
  }
}

define tinc::vpn::node_key_pub(
  $ensure = present,
  $netname = 'ring0',
  $key = ''
){
  # put key into /etc/tinc/${netname}/rsa_key.pub
  file{"/etc/tinc/${netname}/rsa_key.pub":
    ensure => file,
    source => [ "puppet:///modules/site-tinc/keys/$fqdn/rsa_key.pub",
    ]
    owner => root, group => 0, mode => 0644;
  }
}

define tinc::vpn::node_keys (
  $ensure = present,
  $netname = 'ring0'
){
  # add ${name} to file /etc/tinc/nets.boot => autostart
  # tinc::base::add_to_nets.boot{"${name}":}

  tinc::vpn::node_key_priv("${name}":)
  tinc::vpn::node_key_pub("${name}":)
}

