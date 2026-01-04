#!/bin/bash
set -e

# ==================================================
# Kasir Fleet v7 - Bot Manager (VPS / BOT PUSAT)
# TIDAK PERNAH mengakses ~/.toko/
# ==================================================

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="$BASE_DIR/config"

ADMIN_ENV="$CFG_DIR/admin.env"

if [ ! -f "$ADMIN_ENV" ]; then
  echo "❌ config/admin.env tidak ditemukan"
  exit 1
fi

source "$ADMIN_ENV"

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
  echo "❌ BOT_TOKEN atau CHAT_ID belum diset"
  exit 1
fi

send() {
  local MSG="$1"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$MSG" >/dev/null
}

case "$1" in
test)
  send "✅ TEST BOT BERHASIL

Kasir Fleet v7
Server: VPS / Master
Tanggal: $(date)"
  echo "✔ Pesan test terkirim ke Telegram"
  ;;
restart)
  echo "ℹ️ Bot pusat tidak perlu direstart (stateless)"
  ;;
*)
  echo "Usage:"
  echo "  bot_manager.sh test"
  ;;
esac
