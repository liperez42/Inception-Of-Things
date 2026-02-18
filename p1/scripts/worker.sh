#!/bin/sh

apt-get update && apt-get upgrade
apt-get install -y curl

while [! -f /vagrant/k3s_token]; do
    sleep 2
done

TOKEN=$(cat /vagrant/k3s_token)

export INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111"

curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN K3S_URL="https://192.168.56.110:6443"  sh -
