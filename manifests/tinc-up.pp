define tinc::vpn::tinc-up(
  $ensure = present,
  $ip = '',
){

 file { "/etc/tinc/${name}/tinc-up":
    ensure => $ensure,
    content => template('tinc/tinc-up.erb'),
    require => File["/etc/tinc"],
    notify => Service[tinc],
    owner => root, group => 0, mode => 0600;
  }

}

