#!/bin/bash

set -e

service ssh restart

if [ "$1" = "server" ]; then
	service cloudera-scm-server-db start
	service cloudera-scm-server start
	tail -F -n0 /etc/hosts && wait
elif [ "$1" = "agent" ]; then
	service cloudera-scm-agent start
	tail -F -n0 /etc/hosts && wait
else
	"$@"
fi
