#!/bin/bash
STATUS=$(mullvad status 2>/dev/null | head -n 1)

if echo "$STATUS" | grep -q "Connected"; then
    LOC=$(echo "$STATUS" | awk '{print $3}')
    # \Uf0582 ist das VPN-Schild-Icon in Nerd Fonts
    echo -e "{\"text\": \"\Uf0582 $LOC\", \"class\": \"connected\"}"
elif echo "$STATUS" | grep -q "Connecting"; then
    echo -e "{\"text\": \"\Uf0454 ...\", \"class\": \"connecting\"}"
else
    # \Uf0583 ist das durchgestrichene Schild
    echo -e "{\"text\": \"\Uf0583 Off\", \"class\": \"disconnected\"}"
fi
