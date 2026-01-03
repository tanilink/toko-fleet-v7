#!/bin/bash

# Mendapatkan token bot dan chat ID dari file konfigurasi
source ~/.toko/env

# Fungsi untuk mengirim pesan ke Telegram
send_message() {
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" -d text="$1"
}

# Menjalankan perintah /status
status() {
  send_message "📊 [$TOKO_ID]\nStatus: Online\nBattery: $(termux-battery-status | jq -r '.percentage')%"
}

# Menjalankan perintah /backup
backup() {
  ~/.toko/backup.sh
  send_message "Backup selesai"
}

# Fungsi untuk memonitor pesan Telegram dan menjalankan perintah
monitor() {
  LAST_ID=0
  while true; do
    UPD=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$((LAST_ID+1))")
    NEW_UPDATE_ID=$(echo "$UPD" | jq -r '.result[-1].update_id // empty')
    [ -z "$NEW_UPDATE_ID" ] && sleep 2 && continue

    LAST_ID=$NEW_UPDATE_ID
    MSG=$(echo "$UPD" | jq -r '.result[-1].message.text')
    CID=$(echo "$UPD" | jq -r '.result[-1].message.chat.id')
    [ "$CID" != "$CHAT_ID" ] && continue

    case "$MSG" in
      /status) status ;;
      /backup) backup ;;
    esac
  done
}

# Mulai pemantauan pesan Telegram
monitor
