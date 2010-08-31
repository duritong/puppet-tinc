# manifests/init.pp - module to manage tinc-vpn

class tinc {
  case $operatingsystem {
    default: { include tinc::base }
  }

  if $use_shorewall {
    include shorewall::rules::tinc
  }
}
