# $name => Name of the host we want to connect to
define tinc::vpn_net::host(
  $ensure = present,
  $source = absent,
  $source_is_prefix = false,
  $vpn_net
){
 $name_tinc = regsubst("${name}",'[._-]+','','G')

 file { "/etc/tinc/${vpn_net}/hosts/${name_tinc}":
    ensure => $ensure,
    source => $source ? {
      'absent' => "puppet:///modules/site-tinc/hosts/${vpn_net}/${name}",
      default => $source_is_prefix ? {
        false => $source,
        default => "${source}/${name}"
      }
    },
    notify => Service[tinc],
    owner => root, group => 0, mode => 0600;
  }

}

