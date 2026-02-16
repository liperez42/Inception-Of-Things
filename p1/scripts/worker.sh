#! /bin/sh

apt-get update && apt-get upgrade
apt-get install -y curl

while [ ! -f /vagrant_shared/token ]; do
  sleep 2
done

export K3S_TOKEN=$(cat /vagrant_shared/token)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://192.168.56.110:6443 --node-ip=192.168.56.111" sh -
