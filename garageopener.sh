#!/bin/sh

set -e

trap cleanup SIGINT SIGTERM EXIT
 
function cleanup(){
    ps | grep garage | awk '{if($5 != "grep") print $1}' | xargs kill
	echo "cleanup completed"
}

TMPDIR=$1
mqttServer=$2
mqttPort=$3
mqttTopic=$4
garage1Pin=$5
garage2Pin=$6

echo "$(basename "$0") $TMPDIR $mqttServer $mqttPort $mqttTopic $garage1Pin $garage2Pin"

pidfile="$TMPDIR/pidfile"
backpipe="$TMPDIR/backpipe"
out="$TMPDIR/out"
err="$TMPDIR/err"

mkfifo $out $err
<$out logger -p user.notice -t "$(basename "$0")" &
<$err logger -p user.error -t "$(basename "$0")" &
exec >$out 2>$err


[ ! -p "$backpipe" ] && mkfifo $backpipe
echo "(mosquitto_sub -h $mqttServer -p $mqttPort -t $mqttTopic  1>$backpipe) &" 
echo "$!" >"$pidfile"
(mosquitto_sub -h $mqttServer -p $mqttPort -t $mqttTopic  1>$backpipe) &

echo "connected."

while read line; do
    echo "Hey, $TMPDIR $mqttServer $mqttPort $mqttTopic $garage1Pin $garage2Pin $line"
done < $backpipe
