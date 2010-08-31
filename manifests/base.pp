class tinc::base {

   package{'tinc':
       ensure => installed,
   }

   service{tinc:
        ensure => running,
        enable => true,
        hasstatus => true, 
        require => Package[tinc],
   }

  file{'/etc/tinc':
    source => "puppet:///modules/common/empty",
    ensure => directory,
    # purge => true,
    recurse => true,
    require => Package['tinc'],
    # notify => Service['tinc'],
    owner => root, group => 0, mode => 0644;
  }

  file{"/etc/tinc/nets.boot":
    source => [ "puppet:///modules/site-tinc/netsboot/${fqdn}/nets.boot",
                "puppet:///modules/site-tinc/netsboot/nets.boot",
                "puppet:///modules/tinc/netsboot/nets.boot" ],
    notify => Service['tinc'],
    owner => root, group => 0, mode => 0644;
  }

}


