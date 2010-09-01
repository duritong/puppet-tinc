define tinc::vpn::node_key_pub(
  $ensure = present,
  $netname = 'ring0',
  $key = ''
){
  # put key into /etc/tinc/${netname}/rsa_key.pub
  file{"/etc/tinc/${netname}/rsa_key.pub":
    source => "puppet:///modules/site-tinc/keys/$fqdn/rsa_key.pub",
    owner => root, group => 0, mode => 0644;
  }
}
