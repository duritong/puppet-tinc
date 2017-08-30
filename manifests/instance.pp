# create a tinc vpn net
define tinc::instance(
  $ensure                   = 'present',
  $connect_on_boot          = true,
  $tinc_interface           = 'eth0',
  $tinc_address             = undef,
  $tinc_address_to_export   = undef,
  $port                     = '655',
  $port_to_export           = '655',
  $compression              = '10',
  $mode                     = 'switch',
  $options                  = {},
  $tinc_up_content          = undef,
  $tinc_down_content        = undef,
){
  include ::tinc

  # needed in template tinc.conf.erb
  $fqdn_tinc = regsubst($::fqdn,'[._-]+','','G')
  $tinc_config  = "/etc/tinc/${name}/tinc.conf"

  # register net for bootup?
  $boot_ensure = $ensure ? {
    'present' => $connect_on_boot ? {
      true    => 'present',
      default => 'absent'
    },
    default => 'absent'
  }

  # which service do we have to manage?
  if $tinc::uses_systemd {
    $service_name = "tinc@${name}"
    service{$service_name: }

    if $ensure == 'present' {
      # if we don't want to start
      # on boot, we don't need to
      # manage that part of the service
      if $boot_ensure == 'present' {
        Service[$service_name]{
          ensure => running,
          enable => true,
        }
      }
    } else {
      Service[$service_name]{
        ensure => stopped,
        enable => false,
        before => File["/etc/tinc/${name}"],
      }
    }
  } else {
    $service_name = 'tinc'
    # only relevant for non-systemd systems
    if $boot_ensure == 'present' {
      concat::fragment{"tinc_net_${name}":
        content => "${name}\n",
        target  => '/etc/tinc/nets.boot',
        notify  => Service[$service_name],
      }
    }
  }

  file{"/etc/tinc/${name}":
    require => Package['tinc'],
    owner   => root,
    group   => 0,
    mode    => '0600';
  }

  if $ensure == 'present' {
    File["/etc/tinc/${name}"]{
      ensure  => directory,
      notify  => Service[$service_name],
    }
    concat{$tinc_config:
      notify => Service[$service_name],
      owner  => root,
      group  => 0,
      mode   => '0600';
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

    if $tinc_address {
      $host_address = $tinc_address
    } else {
      $host_address = $facts['networking']['interfaces'][$tinc_interface]['ip']
    }
    if $tinc_address_to_export {
      $export_addr = $tinc_address_to_export
    } else {
      $export_addr = $host_address
    }

    # get the keys
    # [ priv, pub ]
    $tinc_keys = tinc_keygen($name,"${tinc::key_source_path}/${name}/${::fqdn}")
    file{
      "/etc/tinc/${name}/rsa_key.priv":
        content => $tinc_keys[0],
        notify  => Service[$service_name],
        owner   => root,
        group   => 0,
        mode    => '0600';
      "/etc/tinc/${name}/rsa_key.pub":
        content => $tinc_keys[1],
        notify  => Service[$service_name],
        owner   => root,
        group   => 0,
        mode    => '0600';
    }
    # export this host and collect all the other hosts
    @@tinc::host{"${fqdn_tinc}@${name}":
      port        => $port_to_export,
      compression => $compression,
      address     => $export_addr,
      public_key  => $tinc_keys[1],
      tag         => "tinc::host_for_${name}",
    }
    Tinc::Host<<| tag == "tinc::host_for_${name}" |>>

    concat::fragment{"tinc_conf_header_${name}":
      target  => $tinc_config,
      content => template('tinc/tinc.conf-header.erb'),
      order   => '100',
    }

    @@tinc::connect_to{"${name}_connect_to_${fqdn_tinc}":
      to      => $fqdn_tinc,
      to_fqdn => $::fqdn,
      target  => $tinc_config,
      tag     => "tinc_${name}_auto",
    }
    Tinc::Connect_to<<| tag == "tinc_${name}_auto" |>>

    file { "/etc/tinc/${name}/tinc-up":
      content => $tinc_up_content,
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0700';
    }
    file { "/etc/tinc/${name}/tinc-down":
      content => $tinc_down_content,
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0700';
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
