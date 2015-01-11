# a host for a certain network
# title must be:
#    hostname@network
#
define tinc::host(
  $public_key,
  $ensure      = present,
  $port        = 655,
  $compression = 10,
) {
  # if absent the net should
  # clean it up by itself
  if $ensure == 'present' {
    validate_re($name,'.+@.+')
    $sp_name = split($name,'@')
    $fqdn_tinc = $sp_name[0]
    $net = $sp_name[1]

    include tinc
    if $tinc::uses_systemd {
      $service_name = "tincd@${net}"
    } else {
      $service_name = 'tinc'
    }

    file{"/etc/tinc/${net}/hosts/${fqdn_tinc}":
      content => template('tinc/host.erb'),
      # to be sure that we manage that net
      require => File["/etc/tinc/${net}/hosts"],
      notify  => Service[$service_name],
      owner   => root,
      group   => 0,
      mode    => '0600';
    }
  }
}
