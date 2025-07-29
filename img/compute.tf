resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8slqa3vkedptmcmgh7" 
      
      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public-a.id
    nat       = true
    # --- Применение Security Group ---
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
    # --------------------------------------------
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "web1" {
  name        = "web1"
  hostname    = "web1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8slqa3vkedptmcmgh7" 

      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private-a.id
    # --- Применение Security Group ---
    security_group_ids = [yandex_vpc_security_group.web-sg.id]
    # --------------------------------------------
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "web2" {
  name        = "web2"
  hostname    = "web2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8slqa3vkedptmcmgh7" 
      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private-b.id
    # --- Применение Security Group ---
    security_group_ids = [yandex_vpc_security_group.web-sg.id]
    # --------------------------------------------
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8slqa3vkedptmcmgh7" 
      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public-a.id
    nat       = true
    # --- Применение Security Group ---
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id]
    # --------------------------------------------
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8slqa3vkedptmcmgh7" 

      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private-a.id
    # --- Применение Security Group ---
    security_group_ids = [yandex_vpc_security_group.elasticsearch-sg.id] # Новая SG
    # --------------------------------------------
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8slqa3vkedptmcmgh7" 

      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public-a.id
    nat       = true
    # --- Применение Security Group ---
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id] 
    # --------------------------------------------
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}