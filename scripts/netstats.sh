#!/bin/bash
# Bepaal het actieve netwerk (werkt voor zowel Wi-Fi als Ethernet)
IFACE=$(ip route | awk '/default/ {print $5; exit}')

if [ -z "$IFACE" ]; then 
    echo '{"connected": false}'
    exit 0
fi

# Haal IP en Gateway op
IP=$(ip -4 -brief a show $IFACE | awk '{print $3}' | cut -d/ -f1)
GW=$(ip route | awk '/default/ {print $3; exit}')

# Haal totaal verzonden/ontvangen bytes op uit de Linux kernel
RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)

# Meet Ping en Packet loss (max 1 seconde de tijd)
PING_RES=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null)
PING=$(echo "$PING_RES" | grep -oP 'time=\K[\d.]+' || echo "0")
LOSS=$(echo "$PING_RES" | grep -oP '\d+(?=% packet loss)' || echo "100")

# Print alles als JSON zodat QML het makkelijk kan lezen
echo "{\"connected\": true, \"ip\":\"$IP\", \"gw\":\"$GW\", \"rx\":$RX, \"tx\":$TX, \"ping\":$PING, \"loss\":$LOSS}"
