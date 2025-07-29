resource "yandex_alb_target_group" "web-servers" {
  name = "web-servers"  # Убрали region_id

  target {
    subnet_id = yandex_vpc_subnet.private-a.id
    ip_address = yandex_compute_instance.web1.network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.private-b.id
    ip_address = yandex_compute_instance.web2.network_interface.0.ip_address
  }
}

resource "yandex_alb_backend_group" "web-backend" {
  name = "web-backend"

  http_backend {
    name = "web-http-backend"
    weight = 1
    port = 80
    target_group_ids = [yandex_alb_target_group.web-servers.id]
    healthcheck {
      timeout = "10s"
      interval = "2s"
      healthy_threshold = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web-router" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "web-host" {
  name = "web-host"
  http_router_id = yandex_alb_http_router.web-router.id
  
  route {
    name = "root"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web-backend.id
        timeout = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web-lb" {
  name = "web-lb"
  network_id = yandex_vpc_network.network.id

  allocation_policy {
    location {
      zone_id = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public-a.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web-router.id
      }
    }
  }
}