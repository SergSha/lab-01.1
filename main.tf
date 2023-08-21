locals {
  user            = "debian"
  ssh_public_key  = "~/.ssh/otus.pub"
  ssh_private_key = "~/.ssh/otus"
}

resource "yandex_vpc_network" "vpc" {
  # folder_id = var.folder_id
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "subnet" {
  # folder_id = var.folder_id
  v4_cidr_blocks = var.subnet_cidrs
  zone           = var.zone
  name           = var.subnet_name
  network_id     = yandex_vpc_network.vpc.id
}

resource "yandex_compute_instance" "instance" {
  count = 3

  name        = "${var.vm_name}-${count.index}"
  hostname    = "${var.vm_name}-${count.index}"
  platform_id = var.platform_id
  zone        = var.zone
  # folder_id   = var.folder_id
  resources {
    cores         = var.cpu
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.disk
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    nat                = var.nat
    ip_address         = var.internal_ip_address
    nat_ip_address     = var.nat_ip_address
  }

  metadata = {
    ssh-keys           = "${local.user}:${file(local.ssh_public_key)}"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      host        = self.network_interface[0].nat_ip_address
      type        = "ssh"
      user        = local.user
      private_key = file(local.ssh_private_key)
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u '${local.user}' --private-key '${local.ssh_private_key}' --become -i '${self.network_interface.0.nat_ip_address},' provision.yml"
  }
}
