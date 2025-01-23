#!/bin/bash

echo "Начинаем установку и настройку прокси-сервера..."

echo "Обновление списка пакетов..."
if sudo apt update; then
    echo "Обновление выполнено успешно"
else
    echo "Ошибка при обновлении пакетов"
fi

echo "Установка Squid..."
if sudo apt install squid -y; then
    echo "Squid успешно установлен"
else
    echo "Ошибка при установке Squid"
    exit 1
fi

echo "Остановка сервиса Squid..."
if sudo systemctl stop squid; then
    echo "Сервис Squid остановлен"
else
    echo "Ошибка при остановке сервиса Squid"
fi

echo "Создание новой конфигурации Squid..."
if sudo tee /etc/squid/squid.conf > /dev/null << EOL
http_port 1382
acl localnet src 0.0.0.0/0
http_access allow localnet
http_access allow localhost
http_access deny all
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
EOL
then
    echo "Конфигурация успешно создана"
else
    echo "Ошибка при создании конфигурации"
    exit 1
fi

echo "Настройка прав доступа..."
if sudo chown proxy:proxy /var/spool/squid && sudo chmod 755 /var/spool/squid; then
    echo "Права доступа настроены"
else
    echo "Ошибка при настройке прав доступа"
fi

echo "Инициализация кэш-директории..."
if sudo squid -z; then
    echo "Кэш-директория инициализирована"
else
    echo "Ошибка при инициализации кэш-директории"
fi

echo "Запуск Squid..."
if sudo systemctl start squid; then
    echo "Squid успешно запущен"
else
    echo "Ошибка при запуске Squid"
    exit 1
fi

echo "Добавление Squid в автозагрузку..."
if sudo systemctl enable squid; then
    echo "Squid добавлен в автозагрузку"
else
    echo "Ошибка при добавлении в автозагрузку"
fi

echo "Проверка статуса Squid..."
sudo systemctl status squid

echo "Настройка файрвола..."
if sudo ufw allow 1382; then
    echo "Порт 1382 открыт в файрволе"
else
    echo "Ошибка при настройке файрвола"
fi

echo "IP адрес сервера:"
hostname -I | awk '{print $1}'

echo "=============================================="
echo "Прокси сервер успешно установлен на порту 1382"
echo "Используйте IP адрес выше для подключения"
echo "=============================================="
