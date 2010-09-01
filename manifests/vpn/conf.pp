# $name => Name of network=ring
define tinc::vpn::conf (
  $ensure = present,
  $connectTo = 'absent',
){

 file { "/etc/tinc/${name}/tinc.conf":
    ensure => $ensure,
    content => template('tinc/tinc.conf.erb'),
    notify => Service[tinc],
    owner => root, group => 0, mode => 0600;
  }

}
