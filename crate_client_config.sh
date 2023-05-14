#!/bin/bash
cd /etc/openvpn/easy-rsa/

# Инициализация переменных окружения
source vars

# Генерация запроса на подпись сертификата и ключа для клиента
./easyrsa gen-req client1 nopass

# Подписание сертификата с помощью CA
./easyrsa sign-req client client1

# Копирование клиентского сертификата и ключа
mkdir -p /etc/openvpn/client-configs/files
cp pki/private/client1.key pki/issued/client1.crt /etc/openvpn/client-configs/files/

# Создание файла .ovpn
cat > /etc/openvpn/client-configs/files/client1.ovpn <<EOF
client
dev tun
proto udp
remote $(wget -qO- eth0.me) 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
<ca>
$(cat /etc/openvpn/easy-rsa/pki/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/client-configs/files/client1.crt)
</cert>
<key>
$(cat /etc/openvpn/client-configs/files/client1.key)
</key>
EOF
