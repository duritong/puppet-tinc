# base setup of tinc
class tinc::base {
  package {'tinc':
    ensure => installed,
  } -> file {'/etc/tinc/nets.boot':
    ensure  => present,
    owner   => root,
    group   => 0,
    mode    => '0600';
  } -> service {'tinc':
    ensure    => running,
    enable    => true,
    hasstatus => true,
  }
}
