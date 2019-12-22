#!/bin/sh

apt update
apt -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common git curl
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
apt -y update
apt -y install docker-ce docker-ce-cli containerd.io docker-compose

systemctl start docker
systemctl enable docker

mkdir -p /etc/docker
mkdir -p /etc/docker/compose

rm -rf /etc/docker/compose/relay
git clone https://github.com/WaxieSDR/webrtc-relay-server.git /etc/docker/compose/relay

cp /etc/docker/compose/relay/docker-compose@.service /lib/systemd/system/
systemctl daemon-reload

echo "TURN_SECRET=secret" > /etc/docker/compose/relay/production.env

if [ "x$1" != "x" ]; then
	curl $1 -o /etc/docker/compose/relay/production.env
fi

systemctl stop docker-compose@relay
systemctl start docker-compose@relay
systemctl enable docker-compose@relay
