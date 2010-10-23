class tinc::centos inherits tinc::base {

  file{'/etc/init.d/tinc':
    source => "puppet:///modules/tinc/${operatingsystem}/tinc.init",
    require => Package['tinc'],
    before => Service['tinc'],
    owner => root, group => 0, mode => 0755;
  }

  file{'/etc/sysconfig/tinc':
    source => [ "puppet:///modules/site-tinc/CentOS/${fqdn}/tinc.sysconfig",
                "puppet:///modules/site-tinc/tinc.sysconfig",
                "puppet:///modules/tinc/${operatingsystem}/tinc.sysconfig" ],
    require => Package['tinc'],
    notify => Service['tinc'],
    owner => root, group => 0, mode => 0644;
  }

  Service['tinc']{
    hasstatus => true,
    require => [ File['/etc/init.d/tinc'], File['/etc/sysconfig/tinc'] ]
  }

}

