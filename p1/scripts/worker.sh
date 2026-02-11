#!/bin/sh

TOKEN=$(ssh -o StrictHostKeyChecking=no vagrant@192.168.56.110 "sudo cat /var/lib/rancher/k3s/server/node-token")

apt-get update
apt-get install -y curl

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-iface eth1" K3S_TOKEN=$TOKEN K3S_URL="https://192.168.56.110:6443" sh -s -

sudo systemctl enable k3s-agent 
sudo systemctl start k3s-agent 
