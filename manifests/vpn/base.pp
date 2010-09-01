define tinc::vpn::base (
  $ensure = present,
  $securefiles = false
){
  file{"/etc/tinc/${name}":
    ensure => directory,
    require => Package['tinc'],
    notify => Service['tinc'],
    owner => root, group => 0, mode => 0644;
  }

  file{"/etc/tinc/${name}/hosts":
    ensure => directory,
    notify => Service['tinc'],
    owner => root, group => 0, mode => 0644;
  }

  # add ${name} to file /etc/tinc/nets.boot => autostart
  #tinc::base::add_to_nets.boot{"${name}":}

  if !$securefiles {
    tinc::vpn::node_keys{"${name}":
      netname => "${name}"
    }

    # always include myself in the hosts dir
    tinc::vpn::hosts{'ring0':
      hostname => "${fqdn}"
    }
  } # else see site-module
  
}

