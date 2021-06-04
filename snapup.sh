#!/bin/sh

## Checks for snaps to upload, if found takes the first from the list and pipes FSNAME + SNAPNAME to a file.
weka fs snapshot |grep -vE 'a01|y50|e02' |grep NONE |awk '{print $3,$5}' |sort -n |head -1 > /tmp/snapupcheck-$(date "+%d%m%Y%H%M")

FSNAME=$(cat /tmp/snapupcheck-$(date "+%d%m%Y%H%M") |awk '{print $1}')
SNAPNAME=$(cat /tmp/snapupcheck-$(date "+%d%m%Y%H%M") |awk '{print $2}')

## Checks whether the file is empty. A non 0 value means the file is empty and thus there are no snaps to upload.
[ -s /tmp/snapupcheck-$(date "+%d%m%Y%H%M") ]
RESULT=$?

## If value is 0 weka will attemp uploading the snapshot. stder and stdout will be dumped to a file.
if [ $RESULT -eq 0 ]; then
weka fs snapshot upload $FSNAME $SNAPNAME >/tmp/snapupstatus 2>&1
fi

## Reads the above dumpfile to determine whether the upload was successful or if weka is busy uploading another snapshot.
if grep 'Snapshot upload has started' /tmp/snapupstatus; then
echo 'Upload is in process'
elif
grep error /tmp/snapupstatus |grep 'currently synchronizing'; then
echo 'Weka is busy. Will get it next time'
fi
