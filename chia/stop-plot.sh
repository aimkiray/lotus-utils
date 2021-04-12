#!/usr/bin/env bash

for PID in $(ps -ef | grep "chia plots create" | grep -v grep | awk '{print $2}')
do
    echo $PID
    kill -9 $PID
done