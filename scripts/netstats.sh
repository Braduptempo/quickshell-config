#!/bin/bash

# 1. Haal alle wifi signalen op en converteer naar een JSON dictionary
SIGNALS_JSON=$(nmcli -t -f SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '!seen[$1]++ && $1!="" { printf "\"%s\":%s,", $1, $2 }' | sed 's/,$//')

IFACE=$(ip route | awk '/default/ {print $5; exit}')

# Als we offline zijn, sturen we alsnog de lijst met signalen in de buurt door!
if [ -z "$IFACE" ]; then 
    echo "{\"connected\": false, \"all_signals\":{$SIGNALS_JSON}}"
    exit 0
fi

IP=$(ip -4 -brief a show $IFACE | awk '{print $3}' | cut -d/ -f1)
GW=$(ip route | awk '/default/ {print $3; exit}')

RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)

PING_RES=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null)
PING=$(echo "$PING_RES" | grep -oP 'time=\K[\d.]+' || echo "0")
LOSS=$(echo "$PING_RES" | grep -oP '\d+(?=% packet loss)' || echo "100")

# Stuur alles inclusief de all_signals array naar QML
echo "{\"connected\": true, \"ip\":\"$IP\", \"gw\":\"$GW\", \"rx\":$RX, \"tx\":$TX, \"ping\":$PING, \"loss\":$LOSS, \"all_signals\":{$SIGNALS_JSON}}"
