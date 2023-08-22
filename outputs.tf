output "external_ip_address_demo_vm" {
  value = yandex_compute_instance.instances[*].network_interface[0].nat_ip_address
}