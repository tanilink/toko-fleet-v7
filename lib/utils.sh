#!/bin/bash

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g;s/--*/-/g;s/^-//;s/-$//'
}

send_telegram() {
  local FILE="$1"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F document=@"$FILE" >/dev/null
}
