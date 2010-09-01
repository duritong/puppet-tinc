define tinc::vpn::node_key_priv(
  $ensure = present,
  $netname = 'ring0',
  $key = ''
){
  # put key into /etc/tinc/${netname}/rsa_key.priv
  file{"/etc/tinc/${netname}/rsa_key.priv":
    source => "puppet:///modules/site-tinc/keys/$fqdn/rsa_key.priv",
    owner => root, group => 0, mode => 0644;
  }
}
