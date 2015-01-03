# create a tinc vpn switch
define tinc::switch(
  $ensure                   = 'present',
  $connect_on_boot          = true,
  $tinc_interface           = 'eth0',
  $tinc_address             = undef,
  $port                     = '655',
  $tinc_internal_interface  = 'eth1',
  $tinc_internal_ip         = 'absent',
  $tinc_internal_netmask    = 'absent',
  $tinc_bridge_interface    = 'absent',
  $compression              = '10',
  $shorewall_zone           = 'absent'
){

  tinc::instance{$name:
    ensure          => $ensure,
    connect_on_boot => $connect_on_boot,
    tinc_interface  => $tinc_interface,
    tinc_address    => $tinc_address,
    port            => $port,
    compression     => $compression,
    mode            => 'switch',
  }

  if $ensure == 'present' {
    require bridge_utils
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
      $tinc_br_netmask = inline_template('<%= n=scope.lookupvar(@tinc_br_netmask_fact); n.nil? ? n : n.split(".").map { |e| e.to_i.to_s(2).rjust(8, "0") }.join.count("1").to_s %>')
      case $tinc_br_netmask {
        '',undef: {
          $tinc_orig_netmask = "::netmask_${tinc_internal_interface}"
          $real_tinc_internal_netmask = inline_template('<%= n=scope.lookupvar(@tinc_orig_netmask); n.nil? ? n : n.split(".").map { |e| e.to_i.to_s(2).rjust(8, "0") }.join.count("1").to_s %>')
        }
        default: { $real_tinc_internal_netmask = $tinc_br_netmask }
      }
    } else {
      $real_tinc_internal_netmask = $tinc_internal_netmask
    }

    Tinc::Instance[$name]{
      tinc_up_content   => template('tinc/switch/tinc-up.erb'),
      tinc_down_content => template('tinc/switch/tinc-down.erb'),
    }


    if $tinc::manage_shorewall {
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
