#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"
INSTALLER_DIR="$BASE_DIR/installers"

source "$CFG_DIR/global.env"
source "$CFG_DIR/admin.env"

mkdir -p "$INSTALLER_DIR"

# ---------- UTIL ----------
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

    # ---------- TUNNEL ----------
    if ! cloudflared tunnel list | grep -q "$TOKO_ID"; then
      cloudflared tunnel create "$TOKO_ID"
    fi

    cloudflared tunnel route dns "$TOKO_ID" "$FULL_DOMAIN" 2>/dev/null || true

    # ---------- REGISTRY ----------
    grep -q "^$TOKO_ID," "$DATA_DIR/registry.csv" \
      || echo "$TOKO_ID,$FULL_DOMAIN,$(date +%F)" >> "$DATA_DIR/registry.csv"

    INSTALLER="$INSTALLER_DIR/$TOKO_ID.sh"

# ================= INSTALLER CABANG =================
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
  echo "❌ Harus dijalankan di TERMUX"
  exit 1
}

# ---------- ENV ----------
PORT=7575
TOKO_ID="$TOKO_ID"
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
BASE_DOMAIN="$BASE_DOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"

# ---------- FOLDER ----------
mkdir -p ~/.toko/logs ~/.termux/boot ~/.shortcuts

cat <<ENV > ~/.toko/env
TOKO_ID="$TOKO_ID"
PORT="$PORT"
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
BASE_DOMAIN="$BASE_DOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
ENV

# ---------- DEP ----------
pkg update -y
pkg install -y cloudflared jq curl zip termux-api procps netcat-openbsd
termux-wake-lock
termux-setup-storage
sleep 1

# ---------- CF LOGIN ----------
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

echo "[\$(date)] START TUNNEL" >> "\$LOG"
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
echo "[\$(date)] STOP TUNNEL" >> "\$LOG"
STOP

# ---------- WATCHDOG ----------
cat <<'DOG' > ~/.toko/watchdog.sh
#!/bin/bash
source ~/.toko/env
LOG="\$HOME/.toko/logs/daily.log"

while true; do
  if ! pgrep -f "cloudflared tunnel run.*\$TOKO_ID" >/dev/null; then
    echo "[\$(date)] WATCHDOG: RESTART" >> "\$LOG"
    bash ~/.toko/start.sh
  fi
  sleep 15
done
DOG

chmod +x ~/.toko/*.sh
ln -sf ~/.toko/start.sh ~/.termux/boot/start.sh
ln -sf ~/.toko/start.sh ~/.shortcuts/Nyalakan_Server.sh

nohup ~/.toko/watchdog.sh >/dev/null 2>&1 &
bash ~/.toko/start.sh

curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendMessage" \
  -d chat_id="\$CHAT_ID" \
  -d text="✅ TOKO ONLINE\n$TOKO_ID\nhttps://$FULL_DOMAIN"

echo "SELESAI. AKSES: https://$FULL_DOMAIN"
EOF
# ===================================================

    chmod +x "$INSTALLER"

    echo
    echo "✔ INSTALLER CABANG DIBUAT"
    echo "FILE: $INSTALLER"
    ;;

  list)
    column -t -s',' "$DATA_DIR/registry.csv"
    ;;

  *)
    echo "Usage:"
    echo "  provision.sh create \"Nama\" \"Lokasi\" [base_domain]"
    echo "  provision.sh list"
    ;;
esac
