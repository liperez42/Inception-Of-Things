#!/bin/sh

apt-get update && apt-get upgrade
apt-get install -y curl

curl -sfL https://get.k3s.io | sh -

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/k3s_token