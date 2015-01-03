# configure base tinc
class tinc(
  $manage_shorewall = false,
  $key_source_path  = '/var/lib/puppet/tinc_keys',
) {
  if $::operatingsystem == 'CentOS' and $::operatingsystemmajrelease >  6 {
    $uses_systemd = true
  } else {
    $uses_systemd = false
  }
  case $::operatingsystem {
    centos: { include tinc::centos }
    debian: { include tinc::debian }
    default: { include tinc::base }
  }
  if $manage_shorewall {
    include shorewall::rules::tinc
  }
}
