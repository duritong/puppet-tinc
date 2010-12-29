define tinc::vpn_net(
  $ensure = present,
  $connect_to_hosts = [],
  $connect_on_boot = true,
  $hosts_source = 'absent',
  $hosts_source_is_prefix = false,
  $key_source_path = 'absent',
  $tinc_interface = 'eth0',
  $tinc_internal_interface = 'eth1',
  $tinc_internal_ip = 'absent',
  $tinc_bridge_interface = 'absent',
  $port = '655',
  $compression = '9',
  $shorewall_zone = 'absent'
){
  include ::tinc

  # needed in template tinc.conf.erb
  $fqdn_tinc = regsubst("${fqdn}",'[._-]+','','G')
  $connect_to_hosts_tinc = regsubst($connect_to_hosts,'[._-]+','','G')

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

  @@file { "/etc/tinc/${vpn_net}/hosts/${name_tinc}":
    ensure => $ensure,
    notify => Service[tinc],
    tag => "tinc_host_${name}",
    owner => root, group => 0, mode => 0600;
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

    if $key_source_path == 'absent' {
      fail("You need to set \$key_source_prefix for $name to generate keys on the master!")
    }
    $tinc_keys = tinc_keygen($name,"${key_source_path}/${name}/${fqdn}")
    file{"/etc/tinc/${name}/rsa_key.priv":
      content => $tinc_keys[1],
      notify => Service[tinc],
      owner => root, group => 0, mode => 0600;
    }
    file{"/etc/tinc/${name}/rsa_key.pub":
      content => $tinc_keys[0],
      notify => Service[tinc],
      owner => root, group => 0, mode => 0600;
    }

    $real_tinc_bridge_interface = $tinc_bridge_interface ? {
      'absent' => "br${name}",
      default => $tinc_bridge_interface
    }

    if $tinc_internal_ip == 'absent' {
      $tinc_orig_ifaddr = "ipaddress_${tinc_internal_interface}"
      $real_tinc_internal_ip = inline_template("<%= scope.lookupvar(tinc_orig_ifaddr) %>")
    } else {
      $real_tinc_internal_ip = $tinc_internal_ip
    }

    file { "/etc/tinc/${name}/tinc-up":
      content => template('tinc/tinc-up.erb'),
      require => Package['bridge-utils'],
      notify => Service['tinc'],
      owner => root, group => 0, mode => 0700;
    }
    file { "/etc/tinc/${name}/tinc-down":
      content => template('tinc/tinc-down.erb'),
      require => Package['bridge-utils'],
      notify => Service['tinc'],
      owner => root, group => 0, mode => 0700;
    }
    File["/etc/tinc/${vpn_net}/hosts/${name_tinc}"]{
      content => template('tinc/host.erb'),
    }
    File<<| tag == "tinc_host_${name}" |>>


    if $use_shorewall {
      $real_shorewall_zone = $shorewall_zone ? {
        'absent' => 'loc',
        default => $shorewall_zone
      }
      shorewall::interface { "${real_tinc_bridge_interface}":
        zone    =>  "${real_shorewall_zone}",
        rfc1918 => true,
        options =>  'routeback,logmartians';
      }
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
