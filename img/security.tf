# web-sg - ��������� �������� ������ �� Zabbix (�� �� ��������� �� zabbix-sg)
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
  # ��������� Zabbix Agent (���� 10050) �� �������, � �� �� SG
  ingress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = [yandex_vpc_subnet.public-a.v4_cidr_blocks[0]] # ������� Zabbix
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# zabbix-sg - ��������� �������� ������ �� ���-�������� (�� �� ��������� �� web-sg)
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix-sg"
  network_id  = yandex_vpc_network.network.id
  ingress {
    protocol       = "TCP"
    port           = 80 # ����� ���� ��� ���-���������� Zabbix
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # --- ���������: ��������� Kibana UI ---
  ingress {
    protocol       = "TCP"
    port           = 5601 # ���� �� ��������� ��� Kibana
    v4_cidr_blocks = ["0.0.0.0/0"] # ������� ��� ���� (��� ������� ����� ����� ��������)
  }
  # -------------------------------------
  # ��������� Zabbix Server (���� 10051) �� �������� ���-��������
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
  # --- ���������: ��������� HTTP-���� Elasticsearch (9200) ��� ����������� ---
  ingress {
    protocol       = "TCP"
    port           = 9200
    # ��������� �� ���� �� (���� Zabbix ��������� Elasticsearch �� ���� �� ��, ��� ������������)
    # ��� �� ������� Elasticsearch, ���� ��� ������. ��� �������� �������� �� ����� �������.
    # ����� ��������� ���� �� ������� SG ��� Elasticsearch � ��������� �� ��.
    # ���� �������� �� ������� private-a (��� Elasticsearch)
    v4_cidr_blocks = [yandex_vpc_subnet.private-a.v4_cidr_blocks[0]]
    # ������������: ���� ������� SG ��� Elasticsearch:
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
    # ��������� �� �������, ��� ��������� Zabbix Server
    v4_cidr_blocks = [yandex_vpc_subnet.public-a.v4_cidr_blocks[0]] # 192.168.10.0/24
    # ������: security_group_id = yandex_vpc_security_group.zabbix-sg.id
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- ���������: Security Group ��� Elasticsearch ---
resource "yandex_vpc_security_group" "elasticsearch-sg" {
  name        = "elasticsearch-sg"
  network_id  = yandex_vpc_network.network.id

  # SSH �� bastion
  ingress {
    protocol       = "TCP"
    port           = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }

  # Elasticsearch API (9200) �� Zabbix (��� �����������)
  ingress {
    protocol       = "TCP"
    port           = 9200
    security_group_id = yandex_vpc_security_group.zabbix-sg.id
  }

  # Elasticsearch API (9200) �� Kibana (���� ����� ����������� ��������)
  # ������������, ��� Kibana ���������� zabbix-sg ��� lb-sg. ��� lb-sg:
  ingress {
    protocol       = "TCP"
    port           = 9200
    security_group_id = yandex_vpc_security_group.lb-sg.id # ��� ����� SG ��� Kibana
  }

  # Elasticsearch API (9200) �� Web-�������� (��� Filebeat)
  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = [
      yandex_vpc_subnet.private-a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private-b.v4_cidr_blocks[0]
    ]
  }

  # ��������� ������
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
# ----------------------------------------------------

# --- (�����������) ���������: Security Group ��� Kibana ---
# ���� �� ������ ��������� SG ��� Kibana, ���������������� ���� ����
# � �������� security_group_ids ��� �� kibana � compute.tf
/*
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  network_id  = yandex_vpc_network.network.id

  # SSH �� bastion
  ingress {
    protocol       = "TCP"
    port           = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }

  # HTTP �� Load Balancer ��� ������� ������������� (Kibana ������ �� 5601)
  ingress {
    protocol       = "TCP"
    port           = 5601 # ��� 80, ���� Kibana �� 80
    v4_cidr_blocks = ["0.0.0.0/0"] # ��� ����� ������������ ������
  }

  # ��������� ������ (��� ����������� � Elasticsearch)
  # ������������, ��� Elasticsearch ��������� � private-a
  egress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = [yandex_vpc_subnet.private-a.v4_cidr_blocks[0]]
    # ��� ���� � Elasticsearch ���� SG:
    # security_group_id = yandex_vpc_security_group.elasticsearch-sg.id
  }

  # ����� ��������� ������ (���� ����� ������)
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
*/
# ---------------------------------------------------------