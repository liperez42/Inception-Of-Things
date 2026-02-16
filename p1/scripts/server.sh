#! /bin/sh

apt-get update && apt-get upgrade
apt-get install -y curl

export INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --advertise-address=192.168.56.110 --node-ip=192.168.56.110"
curl -sfL https://get.k3s.io | sh -

while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

cp /var/lib/rancher/k3s/server/node-token /vagrant_shared/token
