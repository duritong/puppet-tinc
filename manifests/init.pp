# configure base tinc
class tinc(
  $use_shorewall   = false,
  $key_source_path = '/var/lib/puppet/tinc_keys',
) {
  if $::operatingsystem == 'CentOS' and versioncmp($::operatingsystemmajrelease,'6') > 0 {
    $uses_systemd = true
  } else {
    $uses_systemd = false
  }
  case $::operatingsystem {
    centos: { include tinc::centos }
    debian: { include tinc::debian }
    default: { include tinc::base }
  }
  if $use_shorewall {
    include shorewall::rules::tinc
  }
}
