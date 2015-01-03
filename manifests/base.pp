# base setup of tinc
class tinc::base {
  package {'tinc':
    ensure => installed,
  } -> concat{'/etc/tinc/nets.boot':
    owner   => root,
    group   => 0,
    mode    => '0600';
  } -> service {'tinc':
    ensure    => running,
    enable    => true,
    hasstatus => true,
  }
}
