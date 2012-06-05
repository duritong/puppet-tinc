class tinc {
  require bridge_utils
  case $::operatingsystem {
    centos: { include tinc::centos }
    debian: { include tinc::debian }
    default: { include tinc::base }
  }
  if hiera('use_shorewall', false) {
    include shorewall::rules::tinc
  }
}
