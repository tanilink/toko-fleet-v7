#!/bin/bash

# Fungsi untuk mengirimkan pesan umum
send_message() {
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" -d text="$1"
}

# Fungsi untuk membuat slug (format URL)
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g;s/--*/-/g;s/^-//;s/-$//'
}

# Fungsi untuk menampilkan status sistem
system_status() {
  echo "Status Sistem: Toko $TOKO_ID"
  echo "Baterai: $(termux-battery-status | jq -r '.percentage')%"
}
