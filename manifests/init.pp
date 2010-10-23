# manifests/init.pp - module to manage tinc-vpn

class tinc {
  include bridge-utils

  case $operatingsystem {
    centos: { include tinc::centos }
    default: { include tinc::base }
  }

  if $use_shorewall {
    include shorewall::rules::tinc
  }
}
