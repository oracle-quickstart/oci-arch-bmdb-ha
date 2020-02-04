#!/bin/bash
#set -e

TMPFILE=/tmp/tmp$$

### Send stdout, stderr to /var/log/messages/
exec 1> >(logger -s -t $(basename $0)) 2>&1

# -- NFS client
mkdir -p /data1
grep -v /mnt/data1 /etc/fstab > $TMPFILE
echo "10.0.1.6:/mnt/data1 /data1      nfs     defaults        0 0" >> $TMPFILE
cp $TMPFILE /etc/fstab
mount /data1

rm -f $TMPFILE

exit 0

