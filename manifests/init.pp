class tinc {
  require bridge-utils
  case $::operatingsystem {
    centos : { include tinc::centos }
    default : { include tinc::base }
  }
  if hiera('use_shorewall', false) {
    include shorewall::rules::tinc
  }
}
