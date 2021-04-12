#!/usr/bin/env bash

apt-get update
apt-get install python3.7-venv python3.7-distutils git -y
echo "172.16.23.20:/data1 /nfs23020 nfs auto,nofail,hard,rw,nolock,rsize=1048576,wsize=1048576,vers=4.2 0 0" >> /etc/fstab
mkdir /nfs23020
mount -a

cd /root/chia-blockchain/
. ./activate
chia init