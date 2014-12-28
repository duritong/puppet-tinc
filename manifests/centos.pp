# manage centos specific things
class tinc::centos inherits tinc::base {
  if $tinc::uses_systemd {
    file{'/etc/systemd/system/tincd@.service':
      source  => 'puppet:///modules/tinc/CentOS/tinc.systemd',
      require => Package['tinc'],
      owner   => root,
      group   => 0,
      mode    => '0644';
    }
    # systemd manages per instance
    Service['tinc'] {
      ensure => undef,
      enable => false,
    }
  } else {
    file {
      '/etc/sysconfig/tinc' :
        source => [ "puppet:///modules/site_tinc/CentOS/${::fqdn}/tinc.sysconfig",
                    'puppet:///modules/site_tinc/tinc.sysconfig',
                    "puppet:///modules/tinc/${::operatingsystem}/tinc.sysconfig"],
        require => Package['tinc'],
        notify  => Service['tinc'],
        owner   => root,
        group   => 0,
        mode    => '0644';
    }
    Service['tinc'] {
      hasstatus => true,
      hasrestart => true
    }
  }
}
