#!/bin/sh

apt-get update
apt-get install -y curl 

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-iface eth1" K3S_KUBECONFIG_MODE="644" sh -s -

sudo systemctl enable k3s