#!/bin/bash

GW=`/sbin/ip route | awk '/default/ { print $5 }'`

if [ $1 == "start" ]; then
	#Wait for internet connection
	while ! ping -q -w1 -c1 google.com &>/dev/null; do
		echo "No internet connection. Waiting"
		sleep 10
	done
	echo "Internet connection detected"

	#Block proxyv2 port and sctp
	iptables  -I INPUT -p tcp --dport 5555 ! -d 172.30.0.1 -j REJECT
	ip6tables -I INPUT -p tcp --dport 5555 -j REJECT
	iptables  -I INPUT -p sctp -j DROP
	ip6tables -I INPUT -p sctp -j DROP

	#Forward for IPv6 as docker does this with a proxy that causes the IP to be lost
	ip6tables -I PREROUTING -t nat -p tcp --dport 443 -i $GW -j DNAT --to-destination fd00:dead::a
	ip6tables -t nat -I POSTROUTING -o $GW -s fd00:dead::/64 -j MASQUERADE

	#Update docker-compose.yml
	git pull origin master

	#Update images
	docker-compose pull
else
	ip6tables -D PREROUTING -t nat -p tcp --dport 443 -i $GW -j DNAT --to-destination fd00:dead::a
	ip6tables -t nat -D POSTROUTING -o $GW -s fd00:dead::/64 -j MASQUERADE
	iptables  -D INPUT -p tcp --dport 5555 ! -d 172.30.0.1 -j REJECT
	ip6tables -D INPUT -p tcp --dport 5555 -j REJECT
	iptables  -D INPUT -p sctp -j DROP
	ip6tables -D INPUT -p sctp -j DROP
fi
