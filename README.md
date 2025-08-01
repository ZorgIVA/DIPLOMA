# Дипломная работа по профессии «Системный администратор»

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal - для этого достаточно при создании ВМ указать name=example, hostname=examle !!

Важно: используйте по-возможности минимальные конфигурации ВМ:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая.

Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.

### Инфрастуктура:

Посредством terraform и ansible развернуты все 6 серверов: web1 (nginx, subnet private-a), web2 (nginx, subnet private-b), bastion, zabbix, elasticsearch, kibana - все с zabbix agent, доступ по SSH через bastion настроен. 
Создана Target Group (yandex_alb_target_group.web-servers): включает web1 и web2.
Healthcheck настроен на корень (/) и порт 80, протокол HTTP.
Создан HTTP Router (yandex_alb_http_router.web-router).
Создан Application Load Balancer (yandex_alb_load_balancer.web-lb): использует HTTP Router web-router, Listener настроен на порт 80.
Установлено ПО: Elasticsearch, Kibana, Filebeat (ставил с локально скачанных дистрибутивов (по известным причинам)).
Настроены SG (security_group): web-sg - разрешает входящий трафик от Zabbix, zabbix-sg - разрешает входящий трафик от веб-серверов,
Elasticsearch API (9200) от Zabbix (для мониторинга), Elasticsearch API (9200) от Web-серверов (для Filebeat), 
HTTP от Load Balancer или внешних пользователей, lb-sg  и т. д..

<img src = "img\1_1.jpg" width = 100%>
<img src = "img\1_2.jpg" width = 100%>
<img src = "img\1_3.jpg" width = 100%>
<img src = "img\1_4.jpg" width = 100%>
<img src = "img\1_6.jpg" width = 100%>

### Файлы Terraform:

compute: [compute.tf](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/compute.tf)

lb: [lb.tf](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/lb.tf)

main: [main.tf](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/main.tf)

security: [security.tf](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/security.tf)

snapshots: [snapshots.tf](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/snapshots.tf)

terraform.tfvars: [terraform.tfvars](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/terraform.tfvars)

variables: [variables.tf](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/variables.tf)

### Файлы Ansible:

elasticsearch: [elasticsearch.yml](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/elasticsearch.yml)

filebeat_nginx.yml.j2: [filebeat_nginx.yml.j2](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/filebeat_nginx.yml.j2)

filebeat: [filebeat.yml](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/filebeat.yml)

inventory: [inventory.ini](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/inventory.ini)

kibana: [kibana.yml](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/kibana.yml)

vault_password: [vault_password.txt](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/vault_password.txt)

zabbix_agent: [zabbix_agent.yml](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/zabbix_agent.yml)

zabbix_server: [zabbix_server.yml](https://github.com/ZorgIVA/DIPLOMA/blob/master/img/zabbix_server.yml)

### Мониторинг:


<img src = "img\1_5.jpg" width = 100%>
<img src = "img\1_7.jpg" width = 100%>
<img src = "img\1_8.jpg" width = 100%>
<img src = "img\1_9.jpg" width = 100%>

### Логирование :

<img src = "img\2_1.jpg" width = 100%>