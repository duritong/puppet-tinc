# create a tinc vpn_net
define tinc::vpn_net(
  $ensure                   = present,
  $hosts_path               = 'absent',
  $connect_on_boot          = true,
  $key_source_path          = 'absent',
  $tinc_interface           = 'eth0',
  $tinc_internal_interface  = 'eth1',
  $tinc_internal_ip         = 'absent',
  $tinc_internal_netmask    = 'absent',
  $tinc_bridge_interface    = 'absent',
  $override_mtu             = false,
  $port                     = '655',
  $compression              = '10',
  $manage_shorewall         = false,
  $shorewall_zone           = 'absent'
){
  class{'tinc':
    manage_shorewall => $manage_shorewall
  }

  # needed in template tinc.conf.erb
  $fqdn_tinc = regsubst($::fqdn,'[._-]+','','G')
  if $tinc::uses_systemd {
    $service_name = "tincd@${name}"
    service{$service_name:
      ensure => running,
      enable => true,
    }
  } else {
    $service_name = 'tinc'
  }

  file{"/etc/tinc/${name}":
    require => Package['tinc'],
    notify  => Service[$service_name],
    owner   => root,
    group   => 0,
    mode    => '0600';
  }

  $line_ensure = $ensure ? {
    'present' => $connect_on_boot ? {
      true    => 'present',
      default => 'absent'
    },
    default => 'absent'
  }

  file_line{"tinc_boot_net_${name}":
    ensure  => $line_ensure,
    line    => $name,
    path    => '/etc/tinc/nets.boot',
    require => File['/etc/tinc/nets.boot'],
    notify  => Service[$service_name],
  }

  $real_hosts_path = $hosts_path ? {
    'absent'  => "/etc/tinc/${name}/hosts.list",
    default   => $hosts_path
  }

  @@file { "/etc/tinc/${name}/hosts/${fqdn_tinc}":
    ensure  => $ensure,
    tag     => "tinc_host_${name}",
    owner   => root,
    group   => 0,
    mode    => '0600';
  }

  @@file_line{"${fqdn_tinc}_for_${name}":
    ensure => $ensure,
    path   => $real_hosts_path,
    line   => $fqdn_tinc,
    tag    => 'tinc_hosts_file'
  }


  if $ensure == 'present' {
    File["/etc/tinc/${name}"]{
      ensure  => directory,
      require => Package['tinc'],
    }
    file{"/etc/tinc/${name}/hosts":
      ensure  => directory,
      recurse => true,
      purge   => true,
      force   => true,
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0600';
    }

    $tinc_hosts_list = tfile($real_hosts_path)
    $tinc_all_hosts = split($tinc_hosts_list,"\n")
    $tinc_hosts = delete($tinc_all_hosts,$fqdn_tinc)

    file { "/etc/tinc/${name}/tinc.conf":
      content => template('tinc/tinc.conf.erb'),
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0600';
    }

    if $key_source_path == 'absent' {
      fail("You need to set \$key_source_prefix for ${name} to generate keys on the master!")
    }
    $tinc_keys = tinc_keygen($name,"${key_source_path}/${name}/${::fqdn}")
    file{"/etc/tinc/${name}/rsa_key.priv":
      content => $tinc_keys[0],
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0600';
    }
    file{"/etc/tinc/${name}/rsa_key.pub":
      content => $tinc_keys[1],
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0600';
    }

    $real_tinc_bridge_interface = $tinc_bridge_interface ? {
      'absent'  => "br${name}",
      default   => $tinc_bridge_interface
    }

    if $tinc_internal_ip == 'absent' {
      $tinc_br_ifaddr = "::ipaddress_${real_tinc_bridge_interface}"
      $tinc_br_ip = inline_template('<%= scope.lookupvar(@tinc_br_ifaddr) %>')
      case $tinc_br_ip {
        '',undef: {
          $tinc_orig_ifaddr = "::ipaddress_${tinc_internal_interface}"
          $real_tinc_internal_ip = inline_template('<%= scope.lookupvar(@tinc_orig_ifaddr) %>')
        }
        default: { $real_tinc_internal_ip = $tinc_br_ip }
      }
    } else {
      $real_tinc_internal_ip = $tinc_internal_ip
    }
    if $tinc_internal_netmask == 'absent' {
      $tinc_br_netmask_fact = "::netmask_${real_tinc_bridge_interface}"
      $tinc_br_netmask = inline_template('<%= scope.lookupvar(@tinc_br_netmask_fact) %>')
      case $tinc_br_netmask {
        '',undef: {
          $tinc_orig_netmask = "::netmask_${tinc_internal_interface}"
          $real_tinc_internal_netmask = inline_template('<%= scope.lookupvar(@tinc_orig_netmask) %>')
        }
        default: { $real_tinc_internal_netmask = $tinc_br_netmask }
      }
    } else {
      $real_tinc_internal_netmask = $tinc_internal_netmask
    }

    file { "/etc/tinc/${name}/tinc-up":
      content => template('tinc/tinc-up.erb'),
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0700';
    }
    file { "/etc/tinc/${name}/tinc-down":
      content => template('tinc/tinc-down.erb'),
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0700';
    }
    File["/etc/tinc/${name}/hosts/${fqdn_tinc}"]{
      content => template('tinc/host.erb'),
    }
    File<<| tag == "tinc_host_${name}" |>>


    if $manage_shorewall {
      $zone = $shorewall_zone ? {
        'absent'  => 'loc',
        default   => $shorewall_zone
      }
      shorewall::interface { $real_tinc_bridge_interface:
        zone    => $zone,
        rfc1918 => true,
        options => 'routeback,logmartians';
      }
    }

  } else {
    File["/etc/tinc/${name}"]{
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true
    }
  }
}
