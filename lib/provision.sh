#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"
INSTALLER_DIR="$BASE_DIR/installers"

source "$CFG_DIR/global.env"
source "$CFG_DIR/admin.env"

mkdir -p "$INSTALLER_DIR"

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g;s/--*/-/g;s/^-//;s/-$//'
}

CMD="$1"

case "$CMD" in
create)
  NAMA="$2"
  LOKASI="$3"
  BASE_DOMAIN_INPUT="$4"

  [ -z "$NAMA" ] || [ -z "$LOKASI" ] && {
    echo "❌ Nama toko & lokasi wajib"
    exit 1
  }

  BASE_DOMAIN="${BASE_DOMAIN_INPUT:-$BASE_DOMAIN}"
  TOKO_ID="$(slugify "$NAMA")-$(slugify "$LOKASI")"
  FULL_DOMAIN="$TOKO_ID.$BASE_DOMAIN"

  echo "▶ TOKO   : $TOKO_ID"
  echo "▶ DOMAIN : $FULL_DOMAIN"

  # Tunnel Cloudflare
  if ! cloudflared tunnel list | grep -q "$TOKO_ID"; then
    cloudflared tunnel create "$TOKO_ID"
  fi
  cloudflared tunnel route dns "$TOKO_ID" "$FULL_DOMAIN" 2>/dev/null || true

  grep -q "^$TOKO_ID," "$DATA_DIR/registry.csv" \
    || echo "$TOKO_ID,$FULL_DOMAIN,$(date +%F)" >> "$DATA_DIR/registry.csv"

  INSTALLER="$INSTALLER_DIR/$TOKO_ID.sh"

cat <<EOF > "$INSTALLER"
#!/bin/bash
set -e
clear

echo "=============================================="
echo "  KASIR FLEET v7 - INSTALLER CABANG"
echo "=============================================="
echo " TOKO   : $NAMA"
echo " LOKASI : $LOKASI"
echo " DOMAIN : $FULL_DOMAIN"
echo "=============================================="
sleep 1

command -v pkg >/dev/null || {
  echo "❌ Jalankan di TERMUX"
  exit 1
}

PORT=7575
TOKO_ID="$TOKO_ID"
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
BASE_DOMAIN="$BASE_DOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"

mkdir -p ~/.toko/logs ~/.termux/boot ~/.shortcuts

cat <<ENV > ~/.toko/env
TOKO_ID="$TOKO_ID"
PORT="$PORT"
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
BASE_DOMAIN="$BASE_DOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
ENV

pkg update -y
pkg install -y cloudflared jq curl zip termux-api procps netcat-openbsd
termux-wake-lock
termux-setup-storage

[ ! -f ~/.cloudflared/cert.pem ] && cloudflared tunnel login

# ---------- START ----------
cat <<'START' > ~/.toko/start.sh
#!/bin/bash
source ~/.toko/env
LOCK="\$HOME/.toko/lock"
LOG="\$HOME/.toko/logs/daily.log"

[ -f "\$LOCK" ] && exit 0
touch "\$LOCK"
trap "rm -f \$LOCK" EXIT

termux-wake-lock
pkill -f "cloudflared tunnel run.*\$TOKO_ID" 2>/dev/null || true
sleep 1

echo "[\$(date)] START" >> "\$LOG"
cloudflared tunnel run --url http://localhost:\$PORT "\$TOKO_ID" \
  >> "\$LOG" 2>&1 &
sleep 2
rm -f "\$LOCK"
START

# ---------- STOP ----------
cat <<'STOP' > ~/.toko/stop.sh
#!/bin/bash
source ~/.toko/env
LOCK="\$HOME/.toko/lock"
LOG="\$HOME/.toko/logs/daily.log"

[ -f "\$LOCK" ] && exit 0
touch "\$LOCK"
trap "rm -f \$LOCK" EXIT

pkill -f "cloudflared tunnel run.*\$TOKO_ID" 2>/dev/null || true
echo "[\$(date)] STOP" >> "\$LOG"
STOP

# ---------- WATCHDOG ----------
cat <<'DOG' > ~/.toko/watchdog.sh
#!/bin/bash
source ~/.toko/env
LOG="\$HOME/.toko/logs/daily.log"

while true; do
  if ! pgrep -f "cloudflared tunnel run.*\$TOKO_ID" >/dev/null; then
    echo "[\$(date)] WATCHDOG RESTART" >> "\$LOG"
    bash ~/.toko/start.sh
  fi
  sleep 15
done
DOG

# ---------- BOT ----------
cat <<'BOT' > ~/.toko/bot.sh
#!/bin/bash
source ~/.toko/env

LOCK="\$HOME/.toko/lock"
LOG="\$HOME/.toko/logs/daily.log"
OFFSET_FILE="\$HOME/.toko/bot.offset"
API="https://api.telegram.org/bot\$BOT_TOKEN"

send() {
  curl -s -X POST "\$API/sendMessage" \
    -d chat_id="\$CHAT_ID" -d text="\$1" >/dev/null
}

battery() {
  termux-battery-status 2>/dev/null | jq -r '.percentage // "N/A"'
}

handle() {
  case "\$1" in
    /nyala)
      [ -f "\$LOCK" ] && send "⏳ Proses lain berjalan" && return
      send "▶ Menyalakan..."
      bash ~/.toko/start.sh
      send "✅ ONLINE"
      ;;
    /mati)
      [ -f "\$LOCK" ] && send "⏳ Proses lain berjalan" && return
      bash ~/.toko/stop.sh
      send "⛔ OFFLINE"
      ;;
    /status)
      pgrep -f "cloudflared tunnel run.*\$TOKO_ID" >/dev/null \
        && ST="ONLINE" || ST="OFFLINE"
      send "📊 \$TOKO_ID\nStatus: \$ST\nBattery: \$(battery)%"
      ;;
    /help|*)
      send "/nyala /mati /status"
      ;;
  esac
}

OFFSET=\$(cat "\$OFFSET_FILE" 2>/dev/null || echo 0)

while true; do
  UPD=\$(curl -s "\$API/getUpdates?offset=\$OFFSET")
  echo "\$UPD" | jq -c '.result[]?' | while read -r r; do
    UID=\$(echo "\$r" | jq -r '.update_id')
    MSG=\$(echo "\$r" | jq -r '.message.text // empty')
    CID=\$(echo "\$r" | jq -r '.message.chat.id // empty')
    OFFSET=\$((UID+1))
    echo "\$OFFSET" > "\$OFFSET_FILE"
    [ "\$CID" != "\$CHAT_ID" ] && continue
    handle "\$MSG"
  done
  sleep 2
done
BOT

chmod +x ~/.toko/*.sh
ln -sf ~/.toko/start.sh ~/.termux/boot/start.sh
ln -sf ~/.toko/start.sh ~/.shortcuts/Nyalakan_Server.sh

nohup ~/.toko/watchdog.sh >/dev/null 2>&1 &
nohup ~/.toko/bot.sh >/dev/null 2>&1 &
bash ~/.toko/start.sh

curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendMessage" \
  -d chat_id="\$CHAT_ID" \
  -d text="✅ TOKO ONLINE\n$TOKO_ID\nhttps://$FULL_DOMAIN"

echo "SELESAI"
EOF

  chmod +x "$INSTALLER"
  echo "✔ Installer dibuat: $INSTALLER"
  ;;

list)
  column -t -s',' "$DATA_DIR/registry.csv"
  ;;
*)
  echo "Usage:"
  echo "  provision.sh create \"Nama\" \"Lokasi\""
  echo "  provision.sh list"
  ;;
esac
