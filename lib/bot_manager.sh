#!/bin/bash
source .env

while true; do
  UPD=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")
  sleep 5
done
