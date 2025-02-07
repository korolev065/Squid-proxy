#!/bin/bash
echo "Начинаем установку и настройку прокси-сервера с авторизацией..."
echo "Обновление списка пакетов..."
if sudo apt update > /dev/null 2>&1; then
    echo "Обновление выполнено успешно"
else
    echo "Ошибка при обновлении пакетов"
fi
echo "Установка Squid и apache2-utils..."
if sudo apt install squid apache2-utils -y > /dev/null 2>&1; then
    echo "Squid и apache2-utils успешно установлены"
else
    echo "Ошибка при установке Squid или apache2-utils"
    exit 1
fi
echo "Остановка сервиса Squid..."
if sudo systemctl stop squid > /dev/null 2>&1; then
    echo "Сервис Squid остановлен"
else
    echo "Ошибка при остановке сервиса Squid"
fi
PASSWORD=$(openssl rand -base64 12)
USERNAME="user$(openssl rand -hex 4)"
PORT=$(shuf -i 2000-60000 -n 1)
echo "Создание файла с учетными данными..."
if sudo htpasswd -b -c /etc/squid/passwd "$USERNAME" "$PASSWORD" > /dev/null 2>&1; then
    echo "Файл с учетными данными создан"
else
    echo "Ошибка при создании файла с учетными данными"
    exit 1
fi
TMP_CONF=$(mktemp)
cat > "$TMP_CONF" <<__EOF__
http_port $PORT
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid_Proxy
auth_param basic credentialsttl 2 hours
acl auth_users proxy_auth REQUIRED
http_access allow auth_users
http_access deny all
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
__EOF__
if sudo mv "$TMP_CONF" /etc/squid/squid.conf > /dev/null 2>&1; then
    echo "Конфигурация успешно создана"
else
    echo "Ошибка при создании конфигурации"
    exit 1
fi
echo "Настройка прав доступа..."
if sudo chown proxy:proxy /var/spool/squid > /dev/null 2>&1 && sudo chmod 755 /var/spool/squid > /dev/null 2>&1; then
    echo "Права доступа настроены"
else
    echo "Ошибка при настройке прав доступа"
fi
echo "Инициализация кэш-директории..."
if sudo squid -z > /dev/null 2>&1; then
    echo "Кэш-директория инициализирована"
else
    echo "Ошибка при инициализации кэш-директории"
fi
echo "Проверка конфигурации Squid..."
if sudo squid -k parse > /dev/null 2>&1; then
    echo "Конфигурация корректна"
else
    echo "Ошибка в конфигурации Squid. Проверьте /var/log/squid/cache.log"
    exit 1
fi
echo "Запуск Squid..."
if sudo systemctl start squid > /dev/null 2>&1; then
    echo "Squid успешно запущен"
else
    echo "Ошибка при запуске Squid. Проверьте /var/log/squid/cache.log"
    exit 1
fi
echo "Добавление Squid в автозагрузку..."
if sudo systemctl enable squid > /dev/null 2>&1; then
    echo "Squid добавлен в автозагрузку"
else
    echo "Ошибка при добавлении Squid в автозагрузку"
fi
echo "Настройка файрвола..."
if sudo ufw allow "$PORT" > /dev/null 2>&1; then
    echo "Порт $PORT открыт в файрволе"
else
    echo "Ошибка при настройке файрвола"
fi
IP=$(hostname -I | awk '{print $1}')
echo "=============================================="
echo "Прокси-сервер с авторизацией успешно установлен"
echo "Подключайтесь по следующим параметрам:"
echo "  IP: $IP"
echo "  Порт: $PORT"
echo "  Логин: $USERNAME"
echo "  Пароль: $PASSWORD"
echo "=============================================="
