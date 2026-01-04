#!/bin/bash
set -e

# ====================================================
# Kasir Fleet v7 - Provisioner (MASTER / VPS)
# Create toko + kirim installer ke Telegram
# ====================================================

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"
INSTALLER_DIR="$BASE_DIR/installers"

GLOBAL_ENV="$CFG_DIR/global.env"
ADMIN_ENV="$CFG_DIR/admin.env"
REGISTRY="$DATA_DIR/registry.csv"

mkdir -p "$DATA_DIR" "$INSTALLER_DIR"

# ---------- LOAD CONFIG ----------
[ -f "$GLOBAL_ENV" ] && source "$GLOBAL_ENV"
[ -f "$ADMIN_ENV" ] && source "$ADMIN_ENV"

# ---------- UTIL ----------
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g;s/--*/-/g;s/^-//;s/-$//'
}

need_cf_login() {
  if [ ! -f "$HOME/.cloudflared/cert.pem" ]; then
    echo "❌ Cloudflare belum login"
    echo "➡️  Jalankan: cloudflared tunnel login"
    exit 1
  fi
}

send_installer_telegram() {
  local FILE="$1"
  local TXT="$2"
  local TOKO="$3"

  if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "ℹ️ Bot pusat belum dikonfigurasi, skip kirim Telegram"
    return 0
  fi

  echo "📤 Mengirim installer ke Telegram..."

  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="📦 INSTALLER TOKO SIAP\n\nToko: $TOKO\nTanggal: $(date)" >/dev/null

  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F document=@"$FILE" \
    -F caption="Installer Kasir Fleet v7 - $TOKO" >/dev/null

  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F document=@"$TXT" \
    -F caption="Petunjuk Install - $TOKO" >/dev/null

  echo "✔ Installer & petunjuk terkirim ke Telegram"
}

# ---------- CREATE TOKO ----------
create_toko() {
  local NAMA="$1"
  local LOKASI="$2"

  if [ -z "$NAMA" ] || [ -z "$LOKASI" ]; then
    echo "Usage:"
    echo "  provision.sh create \"Nama Toko\" \"Lokasi\""
    exit 1
  fi

  need_cf_login

  TOKO_ID="$(slugify "$NAMA")-$(slugify "$LOKASI")"
  FULL_DOMAIN="$TOKO_ID.$BASE_DOMAIN"

  echo "▶ Membuat toko: $TOKO_ID"
  echo "▶ Domain       : $FULL_DOMAIN"
  echo

  # ---------- CLOUDFLARE ----------
  if ! cloudflared tunnel list | grep -q "$TOKO_ID"; then
    cloudflared tunnel create "$TOKO_ID"
  fi

  cloudflared tunnel route dns "$TOKO_ID" "$FULL_DOMAIN" >/dev/null 2>&1 || true

  # ---------- REGISTRY ----------
  grep -q "^$TOKO_ID," "$REGISTRY" 2>/dev/null || \
    echo "$TOKO_ID,$FULL_DOMAIN,$(date +%Y-%m-%d)" >> "$REGISTRY"

  # ---------- INSTALLER SCRIPT ----------
  INSTALLER_FILE="$INSTALLER_DIR/$TOKO_ID.sh"
  TXT_FILE="$INSTALLER_DIR/$TOKO_ID.txt"

  cat > "$INSTALLER_FILE" <<EOF
#!/bin/bash
# ===============================================
# Kasir Fleet v7 - Installer Cabang
# Toko : $TOKO_ID
# ===============================================

set -e

echo "==============================================="
echo " KASIR FLEET v7 - INSTALLER CABANG"
echo " Toko : $TOKO_ID"
echo "==============================================="

pkg update -y
pkg install -y cloudflared curl jq zip termux-api procps netcat-openbsd

termux-wake-lock
termux-setup-storage

mkdir -p ~/.toko/logs ~/.termux/boot

cat > ~/.toko/env <<ENV
TOKO_ID="$TOKO_ID"
FULL_DOMAIN="$FULL_DOMAIN"
BASE_DOMAIN="$BASE_DOMAIN"
PORT=7575
BOT_PRIMARY="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
ENV

cat > ~/.toko/start.sh <<'EOS'
#!/bin/bash
source ~/.toko/env
termux-wake-lock
pkill -f cloudflared || true
cloudflared tunnel run --url http://localhost:\$PORT "\$TOKO_ID" >/dev/null 2>&1 &
EOS

cat > ~/.toko/watchdog.sh <<'EOS'
#!/bin/bash
source ~/.toko/env
while true; do
  if ! pgrep cloudflared >/dev/null; then
    cloudflared tunnel run --url http://localhost:\$PORT "\$TOKO_ID" >/dev/null 2>&1 &
  fi
  sleep 10
done
EOS

chmod +x ~/.toko/*.sh
ln -sf ~/.toko/start.sh ~/.termux/boot/start.sh

nohup ~/.toko/watchdog.sh >/dev/null 2>&1 &
nohup ~/.toko/start.sh >/dev/null 2>&1 &

echo "✔ INSTALL SELESAI - TOKO ONLINE"
EOF

  chmod +x "$INSTALLER_FILE"

  # ---------- PETUNJUK TXT ----------
  cat > "$TXT_FILE" <<EOF
PETUNJUK INSTALL KASIR FLEET v7
====================================

TOKO :
$TOKO_ID

LANGKAH INSTALL DI TABLET :

1. Install Termux dari Play Store
2. Buka Termux
3. Jalankan perintah berikut:

   bash $TOKO_ID.sh

CATATAN :
- Pastikan internet aktif
- Jangan tutup Termux saat install
- Setelah selesai, toko langsung ONLINE

Jika ada kendala, hubungi admin pusat.
EOF

  echo "✔ Installer dibuat : $INSTALLER_FILE"
  echo "✔ Petunjuk dibuat  : $TXT_FILE"
  echo

  send_installer_telegram "$INSTALLER_FILE" "$TXT_FILE" "$TOKO_ID"
}

# ---------- ENTRY ----------
case "$1" in
create)
  shift
  create_toko "$@"
  ;;
*)
  echo "Usage:"
  echo "  provision.sh create \"Nama Toko\" \"Lokasi\""
  ;;
esac
