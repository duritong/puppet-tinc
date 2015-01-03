# a wrapper define to be able
# to exclude myself from being
# collected
define tinc::connect_to(
  $to,
  $to_fqdn,
  $target,
){
  if $::fqdn != $to_fqdn {
    concat::fragment{
      $name:
        target  => $target,
        content => "ConnectTo = ${to}\n",
        order   => '500',
    }
  }
}
