#!/usr/bin/env bash
AUTO_PID=$(ps -ef | grep auto.sh | grep -v grep | tail -n 1 | awk '{print $2}')
echo $AUTO_PID
kill $AUTO_PID