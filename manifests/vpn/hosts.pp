# $name => Name of network=ring
define tinc::vpn::hosts (
  $ensure = present,
  $hostname = absent,
){

 file { "/etc/tinc/${name}/hosts/${hostname}":
    ensure => $ensure,
    source => [ "puppet:///modules/site-tinc/keys/hosts/${hostname}",
    ]
    require => File["/etc/tinc","/etc/tinc/hosts"],
    notify => Service[tinc],
    owner => root, group => 0, mode => 0600;
  }

}

