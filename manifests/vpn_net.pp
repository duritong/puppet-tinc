define tinc::vpn_net(
  $ensure = present,
  $connect_to_hosts = [],
  $connect_on_boot = true,
  $hosts_source = 'absent',
  $hosts_source_is_prefix = false,
  $key_source_prefix = 'absent',
  $tinc_ip = 'absent',
  $tinc_interface = 'absent',
  $tinc_bridge_interface = 'absent'
){
  include ::tinc

  # needed in template tinc.conf.erb
  $fqdn_tinc = regsubst("${fqdn}",'[._-]+','','G')
  $connect_to_hosts_tinc = regsubst("${connect_to_hosts}",'[._-]+','','G')

  file{"/etc/tinc/${name}":
    require => Package['tinc'],
    notify => Service['tinc'],
    owner => root, group => 0, mode => 0600;
  }

  line{"tinc_boot_net_${name}":
    ensure => $ensure ? {
      'present' => $connect_on_boot ? {
        true => 'present',
        default => 'absent'
      },
      default => 'absent'
    },
    line => $name,
    file => '/etc/tinc/nets.boot',
    require => File['/etc/tinc/nets.boot'],
    notify => Service['tinc'],
  }

  if $ensure == 'present' {
    File["/etc/tinc/${name}"]{
      ensure => directory,
    }
    file{"/etc/tinc/${name}/hosts":
      source => 'puppet:///modules/common/empty',
      ensure => directory,
      recurse => true,
      purge => true,
      force => true,
      require => Package['tinc'],
      notify => Service['tinc'],
      owner => root, group => 0, mode => 0600;
    }

    file { "/etc/tinc/${name}/tinc.conf":
      content => template('tinc/tinc.conf.erb'),
      notify => Service[tinc],
      owner => root, group => 0, mode => 0600;
    }

    file{"/etc/tinc/${name}/rsa_key.priv":
      source => $key_source_prefix ? {
        'absent' => "puppet:///modules/site-tinc/keys/${name}/${fqdn}/rsa_key.priv",
        default => "${key_source_prefix}/${name}/${fqdn}/rsa_key.priv",
      },
      notify => Service[tinc],
      owner => root, group => 0, mode => 0600;
    }
    file{"/etc/tinc/${name}/rsa_key.pub":
      source => $key_source_prefix ? {
        'absent' => "puppet:///modules/site-tinc/keys/${name}/${fqdn}/rsa_key.pub",
        default => "${key_source_prefix}/${name}/${fqdn}/rsa_key.pub",
      },
      notify => Service[tinc],
      owner => root, group => 0, mode => 0600;
    }


    # always include myself in the hosts dir
    tinc::vpn_net::host{$fqdn:
      source => $hosts_source,
      source_is_prefix => $hosts_source_is_prefix,
      vpn_net => $name
    }
    # include all the hosts we should connect to
    tinc::vpn_net::host{$connect_to_hosts:
      source => $hosts_source,
      source_is_prefix => $hosts_source_is_prefix,
      vpn_net => $name
    }

    $real_tinc_bridge_interface = $tinc_bridge_interface ? {
      'absent' => "br${name}",
      default => $tinc_bridge_interface
    }
    $real_tinc_ip = $tinc_ip ? {
      'absent' => $ip,
      default => $tinc_ip
    }
    file { "/etc/tinc/${name}/tinc-up":
      content => template('tinc/tinc-up.erb'),
      require => Package['bridge-utils'],
      notify => Service['tinc'],
      owner => root, group => 0, mode => 0700;
    }

  } else {
    File["/etc/tinc/${name}"]{
      ensure => absent,
      recurse => true,
      purge => true,
      force => true
    }
  }
}
