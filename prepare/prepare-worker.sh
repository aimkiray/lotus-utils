#!/bin/bash

set -eo pipefail

sudo sed -i 's/cn.archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list
sudo sed -i 's/us.archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list
sudo sed -i 's/archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list

sudo apt update
apt install -y mesa-opencl-icd ocl-icd-opencl-dev ntpdate ubuntu-drivers-common nfs-common

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate time.apple.com

echo 'options sunrpc tcp_slot_table_entries=128' >> /etc/modprobe.d/sunrpc.conf
echo 'options sunrpc tcp_max_slot_table_entries=128' >>  /etc/modprobe.d/sunrpc.conf
sysctl -w sunrpc.tcp_slot_table_entries=128

ulimit -n 1048576
sed -i "/nofile/d" /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "root hard nofile 1048576" >> /etc/security/limits.conf
echo "root soft nofile 1048576" >> /etc/security/limits.conf

apt install -y nvidia-driver-440-server