#!/bin/bash

# Обновление и установка необходимых пакетов
apt-get update
apt-get upgrade -y
apt-get install openvpn easy-rsa iptables-persistent -y

# Копирование EasyRSA в /etc/openvpn
cp -r /usr/share/easy-rsa/ /etc/openvpn

# Инициализация и создание сертификатов
cd /etc/openvpn/easy-rsa/
source vars
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh

# Копирование файлов сервера в /etc/openvpn
cd /etc/openvpn/easy-rsa/pki
cp dh.pem ca.crt issued/server.crt private/server.key /etc/openvpn

# Создание файла конфигурации OpenVPN
echo 'port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222"
push "dhcp-option DNS 208.67.220.220"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3' > /etc/openvpn/server.conf

# Включение IP-переадресации
echo 'net.ipv4.ip_forward=1' | tee -a /etc/sysctl.conf
sysctl -p

# Настройка правил маскарадинга в iptables
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Сохранение правил iptables, чтобы они настройки работали после перезагрузки (для ipv4)
sudo sh -c 'iptables-save > /etc/iptables/rules.v4'
