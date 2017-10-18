#!/bin/bash

set -e

service ssh restart
#dd if=/dev/zero of=/root/storagefile bs=1G count=20

if [ "$#" -eq  "0" ]; then
	tail -F -n0 /etc/hosts && wait
else
	"$@"
fi
