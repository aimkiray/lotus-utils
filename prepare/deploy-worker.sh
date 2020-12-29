#!/usr/bin/env bash

HOST_IP=$(ip route get 255.255.255.255 | grep -Po '(?<=src )(\d{1,3}.){4}' | xargs)

sed -i "s/__IP__/$HOST_IP/g" systemd-worker-env.conf

cp filecash-worker.service /etc/systemd/system/filecash-worker.service

mkdir /tank1/filecash
mkdir /tank1/filecash-tmp

systemctl daemon-reload
systemctl enable filecash-worker