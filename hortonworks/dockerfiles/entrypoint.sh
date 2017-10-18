#!/bin/bash

set -e

service ssh restart

if [ "$1" = "server" ]; then
	ambari-server setup --silent --verbose
	ambari-server start --skip-database-check
	tail -F -n0 /etc/hosts && wait
elif [ "$1" = "agent" ]; then
	ambari-agent start
	tail -F -n0 /etc/hosts && wait
else
	"$@"
fi
