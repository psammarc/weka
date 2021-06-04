#!/bin/sh

TMPDIR="/tmp/snapup"

## Cheks that folder /tmp/snapup is present, if not it will be created.
if [ ! -d $TMPDIR ]; then
        mkdir -p $TMPDIR
fi

CHECK="$TMPDIR/snap-$(date "+%d%m%Y%H%M")"

## Checks for snaps to upload, if found takes the first from the list and pipes FSNAME + SNAPNAME to a file.
weka fs snapshot |grep -vE 'a01|y50|e02' |grep NONE |awk '{print $3,$5}' |sort -n |head -1 >$CHECK

FSNAME=$(cat $CHECK |awk '{print $1}')
SNAPNAME=$(cat $CHECK |awk '{print $2}')

## Checks whether the file is empty. A non 0 value means the file is empty and thus there are no snaps to upload.
[ -s $CHECK ]
RESULT=$?

DUMPFILE="$TMPDIR/status"
## If value is 0 weka will attemp uploading the snapshot. stder and stdout will be dumped to a file.
if [ $RESULT -eq 0 ]; then
weka fs snapshot upload $FSNAME $SNAPNAME >$DUMPFILE 2>&1
fi

LOGDIR="/var/log/snapup"

## Cheks that folder /var/log/snapup is present, if not it will be created.
if [ ! -d $LOGDIR ]; then
        mkdir -p $LOGDIR
fi

DAILYLOG="$LOGDIR/snapup-$(date "+%d%m%Y")"

## Reads $DUMPFILE to determine whether the upload was successful or if weka is busy uploading another snapshot.
if grep 'Snapshot upload has started' $DUMPFILE; then
echo "$(date "+%d.%m.%Y.%H.%M.%S") '$FSNAME $SNAPNAME' upload is in process." >> $DAILYLOG
elif
grep error $DUMPFILE |grep 'currently synchronizing'; then
echo "$(date "+%d.%m.%Y.%H.%M.%S") Weka is busy! Will get '$FSNAME $SNAPNAME' next time." >> $DAILYLOG
fi
