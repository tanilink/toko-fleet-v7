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

# ---------- COMMAND ----------
CMD="$1"

case "$CMD" in
  create)
    NAMA_TOKO="$2"
    LOKASI="$3"
    BASE_DOMAIN_INPUT="$4"

    if [ -z "$NAMA_TOKO" ] || [ -z "$LOKASI" ]; then
      echo "❌ Nama toko & lokasi wajib diisi"
      exit 1
    fi

    BASE_DOMAIN="${BASE_DOMAIN_INPUT:-$BASE_DOMAIN}"

    SUBDOMAIN="$(slugify "$NAMA_TOKO")-$(slugify "$LOKASI")"
    TOKO_ID="$SUBDOMAIN"
    FULL_DOMAIN="$SUBDOMAIN.$BASE_DOMAIN"

    echo "▶ Membuat toko: $TOKO_ID"
    echo "▶ Domain       : $FULL_DOMAIN"

    # ---------- CLOUDFARE TUNNEL ----------
    if ! cloudflared tunnel list | grep -q "$TOKO_ID"; then
      cloudflared tunnel create "$TOKO_ID"
    fi

    cloudflared tunnel route dns "$TOKO_ID" "$FULL_DOMAIN" 2>/dev/null || true

    # ---------- REGISTRY ----------
    if ! grep -q "^$TOKO_ID," "$DATA_DIR/registry.csv"; then
      echo "$TOKO_ID,$SUBDOMAIN,$(date +%F)" >> "$DATA_DIR/registry.csv"
    fi

    # ---------- INSTALLER FILE ----------
    INSTALLER_FILE="$INSTALLER_DIR/$TOKO_ID.sh"

    cat <<EOF > "$INSTALLER_FILE"
#!/bin/bash
set -e
clear

echo "=============================================="
echo "  KASIR FLEET v7 - INSTALLER CABANG"
echo "=============================================="
echo "  TOKO   : $NAMA_TOKO"
echo "  LOKASI : $LOKASI"
echo "=============================================="
sleep 1

# ---------- CHECK TERMUX ----------
if ! command -v pkg >/dev/null; then
  echo "❌ Installer ini hanya untuk TERMUX Android"
  exit 1
fi

# ---------- ENV ----------
PORT=7575
TOKO_ID="$TOKO_ID"
CHAT_ID="$CHAT_ID"
BOT_TOKEN="$BOT_TOKEN"
BASE_DOMAIN="$BASE_DOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"

# ---------- FOLDER ----------
mkdir -p ~/.toko/logs ~/.termux/boot ~/.shortcuts

cat <<ENV > ~/.toko/env
TOKO_ID="$TOKO_ID"
PORT="$PORT"
CHAT_ID="$CHAT_ID"
BOT_TOKEN="$BOT_TOKEN"
BASE_DOMAIN="$BASE_DOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
ENV

# ---------- DEPENDENCY ----------
echo "[1/5] Install dependency..."
pkg update -y
pkg install -y cloudflared jq curl zip termux-api procps netcat-openbsd

termux-wake-lock
termux-setup-storage
sleep 1

# ---------- CLOUDFLARE ----------
echo "[2/5] Login Cloudflare (jika diminta)..."
if [ ! -f ~/.cloudflared/cert.pem ]; then
  cloudflared tunnel login
fi

# ---------- SERVICE ----------
cat <<'SERVICE' > ~/.toko/start.sh
#!/bin/bash
source ~/.toko/env

termux-wake-lock
pkill -f cloudflared || true

cloudflared tunnel run --url http://localhost:\$PORT "\$TOKO_ID" \
  >/dev/null 2>&1 &
SERVICE

chmod +x ~/.toko/start.sh
ln -sf ~/.toko/start.sh ~/.termux/boot/start.sh
ln -sf ~/.toko/start.sh ~/.shortcuts/Nyalakan_Server.sh

# ---------- START ----------
echo "[3/5] Menjalankan tunnel..."
bash ~/.toko/start.sh

# ---------- NOTIFY ----------
curl -s -X POST "https://api.telegram.org/bot\$BOT_TOKEN/sendMessage" \
  -d chat_id="\$CHAT_ID" \
  -d text="✅ TOKO ONLINE\nToko: $TOKO_ID\nDomain: $FULL_DOMAIN"

echo "[5/5] SELESAI"
echo "Akses: https://$FULL_DOMAIN"
EOF

    chmod +x "$INSTALLER_FILE"

    echo
    echo "✔ INSTALLER BERHASIL DIBUAT"
    echo "------------------------------------------"
    echo "FILE : $INSTALLER_FILE"
    echo
    echo "Kirim ke operator:"
    echo "  bash $TOKO_ID.sh"
    echo "------------------------------------------"
    ;;

  list)
    column -t -s',' "$DATA_DIR/registry.csv"
    ;;

  *)
    echo "Usage:"
    echo "  provision.sh create \"Nama Toko\" \"Lokasi\" [base_domain]"
    echo "  provision.sh list"
    ;;
esac
