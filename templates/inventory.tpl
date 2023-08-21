
[all]
%{ for instance in instances ~}
${ instance["name"] } ansible_host=${ instance.network_interface[0].nat_ip_address }
%{ endfor ~}
