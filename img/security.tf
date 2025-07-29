# web-sg - разрешает входящий трафик от Zabbix (но не ссылается на zabbix-sg)
resource "yandex_vpc_security_group" "web-sg" {
  name        = "web-sg"
  network_id  = yandex_vpc_network.network.id
  ingress {
    protocol       = "TCP"
    port           = 80
    security_group_id = yandex_vpc_security_group.lb-sg.id
  }
  ingress {
    protocol       = "TCP"
    port           = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }
  # Разрешаем Zabbix Agent (порт 10050) из подсети, а не по SG
  ingress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = [yandex_vpc_subnet.public-a.v4_cidr_blocks[0]] # Подсеть Zabbix
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# zabbix-sg - разрешает входящий трафик от веб-серверов (но не ссылается на web-sg)
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix-sg"
  network_id  = yandex_vpc_network.network.id
  ingress {
    protocol       = "TCP"
    port           = 80 # Может быть для веб-интерфейса Zabbix
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # --- Добавлено: Разрешить Kibana UI ---
  ingress {
    protocol       = "TCP"
    port           = 5601 # Порт по умолчанию для Kibana
    v4_cidr_blocks = ["0.0.0.0/0"] # Открыть для всех (или укажите более узкий диапазон)
  }
  # -------------------------------------
  # Разрешаем Zabbix Server (порт 10051) из подсетей веб-серверов
  ingress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = [
      yandex_vpc_subnet.private-a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private-b.v4_cidr_blocks[0]
    ]
  }
  ingress {
    protocol       = "TCP"
    port           = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }
  # --- Добавлено: Разрешить HTTP-порт Elasticsearch (9200) для мониторинга ---
  ingress {
    protocol       = "TCP"
    port           = 9200
    # Разрешаем от себя же (если Zabbix мониторит Elasticsearch на этой же ВМ, что маловероятно)
    # Или от подсети Elasticsearch, если она другая. Для простоты разрешим от своей подсети.
    # Более правильно было бы создать SG для Elasticsearch и ссылаться на неё.
    # Пока разрешим из подсети private-a (где Elasticsearch)
    v4_cidr_blocks = [yandex_vpc_subnet.private-a.v4_cidr_blocks[0]]
    # Альтернатива: Если создана SG для Elasticsearch:
    # security_group_id = yandex_vpc_security_group.elasticsearch-sg.id
  }
  # --------------------------------------------------------------------------

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "lb-sg" {
  name        = "lb-sg"
  network_id  = yandex_vpc_network.network.id
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-sg"
  network_id  = yandex_vpc_network.network.id
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 10050
    # Разрешаем от подсети, где находится Zabbix Server
    v4_cidr_blocks = [yandex_vpc_subnet.public-a.v4_cidr_blocks[0]] # 192.168.10.0/24
    # Вместо: security_group_id = yandex_vpc_security_group.zabbix-sg.id
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Добавлено: Security Group для Elasticsearch ---
resource "yandex_vpc_security_group" "elasticsearch-sg" {
  name        = "elasticsearch-sg"
  network_id  = yandex_vpc_network.network.id

  # SSH от bastion
  ingress {
    protocol       = "TCP"
    port           = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }

  # Elasticsearch API (9200) от Zabbix (для мониторинга)
  ingress {
    protocol       = "TCP"
    port           = 9200
    security_group_id = yandex_vpc_security_group.zabbix-sg.id
  }

  # Elasticsearch API (9200) от Kibana (если будет подключение напрямую)
  # Предполагаем, что Kibana использует zabbix-sg или lb-sg. Для lb-sg:
  ingress {
    protocol       = "TCP"
    port           = 9200
    security_group_id = yandex_vpc_security_group.lb-sg.id # Или новая SG для Kibana
  }

  # Elasticsearch API (9200) от Web-серверов (для Filebeat)
  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = [
      yandex_vpc_subnet.private-a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private-b.v4_cidr_blocks[0]
    ]
  }

  # Исходящий трафик
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
# ----------------------------------------------------

# --- (Опционально) Добавлено: Security Group для Kibana ---
# Если вы хотите отдельную SG для Kibana, раскомментируйте этот блок
# и обновите security_group_ids для ВМ kibana в compute.tf
/*
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  network_id  = yandex_vpc_network.network.id

  # SSH от bastion
  ingress {
    protocol       = "TCP"
    port           = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }

  # HTTP от Load Balancer или внешних пользователей (Kibana обычно на 5601)
  ingress {
    protocol       = "TCP"
    port           = 5601 # Или 80, если Kibana на 80
    v4_cidr_blocks = ["0.0.0.0/0"] # Или более ограниченный доступ
  }

  # Исходящий трафик (для подключения к Elasticsearch)
  # Предполагаем, что Elasticsearch находится в private-a
  egress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = [yandex_vpc_subnet.private-a.v4_cidr_blocks[0]]
    # Или если у Elasticsearch есть SG:
    # security_group_id = yandex_vpc_security_group.elasticsearch-sg.id
  }

  # Общий исходящий трафик (если нужно больше)
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
*/
# ---------------------------------------------------------