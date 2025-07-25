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
<img src = "img\1_5.jpg" width = 100%>
<img src = "img\1_6.jpg" width = 100%>