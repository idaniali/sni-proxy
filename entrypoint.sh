#!/bin/sh

SOCKS_IP="${SOCKS_IP:-127.0.0.1}"
SOCKS_PORT="${SOCKS_PORT:-1080}"

ip tuntap add mode tun dev tun0
ip addr add 192.168.100.1/24 dev tun0
ip link set dev tun0 up

iptables -t mangle -A OUTPUT ! --destination 192.168.0.0/16 -p tcp --dport 80 -j MARK --set-mark 1
iptables -t mangle -A OUTPUT ! --destination 192.168.0.0/16 -p tcp --dport 443 -j MARK --set-mark 1

echo "1 mymark" >> /etc/iproute2/rt_tables

ip route add default via 192.168.100.1 dev tun0 table mymark
ip rule add fwmark 1 table mymark

sed "s/{IP}/${IP}/" /etc/dnsmasq.tpl > /etc/dnsmasq.conf
dnsmasq -khR & \
sniproxy -c /etc/sniproxy.conf -f & \
/tun2socks -device tun0 -proxy socks5://${SOCKS_IP}:${SOCKS_PORT}
