#!/usr/bin/env bash

HOST_IP=$(ip route get 255.255.255.255 | grep -Po '(?<=src )(\d{1,3}.){4}' | xargs)

sed -i "s/<HOST_IP>/$HOST_IP/g" systemd-worker-env.conf

cp -f lotus-worker.service /etc/systemd/system/lotus-worker.service

systemctl daemon-reload
systemctl enable lotus-worker