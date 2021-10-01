#!/bin/sh

ps | grep garage | awk '{if($5 != "grep" && ($5 == "logger" || $5 == "mosquitto_sub")) print $1}' | xargs kill >/dev/null 2> /dev/null
  
[ -z "$1" ] && rm -fr /tmp/garageopener* && TMPDIR=$(mktemp -d -t garageopener.XXXXXX)  || TMPDIR=$1
mqttServer=$(uci get garageopener.mqtt.server)
mqttPort=$(uci get garageopener.mqtt.port)
mqttTopic=$(uci get garageopener.mqtt.topic)
garage1Pin=$(uci get garageopener.gpio.garage1pin)
garage2Pin=$(uci get garageopener.gpio.garage2pin)

pidfile="$TMPDIR/pidfile"
backpipe="$TMPDIR/backpipe"
out="$TMPDIR/out"
err="$TMPDIR/err"

mkfifo "$out" "$err"
<"$out" logger -p user.notice -t "$(basename "$0")" &
<"$err" logger -p user.error -t "$(basename "$0")" &
exec >"$out" 2>"$err"

echo "Temp Folder $TMPDIR"

uci show garageopener

fast-gpio set "$garage1Pin" 0
fast-gpio set "$garage2Pin" 0

[ ! -p "$backpipe" ] && mkfifo "$backpipe"

echo "$!" >"$pidfile"
(mosquitto_sub -h "$mqttServer" -p "$mqttPort" -t "$mqttTopic"	1>"$backpipe") &

echo "connected."

while read -r line; do
	echo "Message : $line"
	if [ "$line" = "garage1Action" ]; then
		fast-gpio set "$garage1Pin" 1
		sleep 2
		fast-gpio set "$garage1Pin" 0
		if [ "$(uci get garageopener.state.garage1)" = "closed" ]; then
			echo "garage 1 opened"
			uci set garageopener.state.garage1=open
			uci commit
			mosquitto_pub -h "$mqttServer" -p "$mqttPort" -t "garageState" -m "garage1Open"
		else
			echo "garage 1 closed"
			uci set garageopener.state.garage1=closed
			uci commit
			mosquitto_pub -h "$mqttServer" -p "$mqttPort" -t "garageState" -m "garage1Closed"
		fi
	fi
	if [ "$line" = "garage2Action" ]; then
		fast-gpio set "$garage2Pin" 1
		sleep 2
		fast-gpio set "$garage2Pin" 0
		if [ "$(uci get garageopener.state.garage2)" = "closed" ]; then
			echo "garage 2 opened"
			uci set garageopener.state.garage2=open
			uci commit
			mosquitto_pub -h "$mqttServer" -p "$mqttPort" -t "garageState" -m "garage2Open"
		else
			echo "garage 2 closed"
			uci set garageopener.state.garage2=closed
			uci commit
			mosquitto_pub -h "$mqttServer" -p "$mqttPort" -t "garageState" -m "garage2Closed"
		fi
	fi
	if [ "$line" = "garageReboot" ]; then
		reboot
	fi
done < "$backpipe"
