#!/bin/bash
set -e
BASE_DIR="/opt/kasir-fleet"
ENV="$BASE_DIR/.env"

mkdir -p "$BASE_DIR/data"

if [ ! -f "$ENV" ]; then
cat > "$ENV" <<EOF
BASE_DOMAIN=kasiron.my.id
BOT_TOKEN=
CHAT_ID=
EOF
fi

source "$ENV"

clear
echo "================================================="
echo "        KASIR FLEET v7 - MASTER DASHBOARD"
echo "================================================="
echo " Base Domain : $BASE_DOMAIN"
echo " Bot Token   : ${BOT_TOKEN:0:10}..."
echo " Chat ID     : $CHAT_ID"
echo "================================================="
echo
echo "[01] Login Cloudflare"
echo "[02] Set Bot Token"
echo "[03] Set Chat ID"
echo "[04] Buat Toko Baru"
echo "[05] Rotate Base Domain"
echo "[06] Lihat Daftar Toko"
echo "[00] Keluar"
echo
read -p "Pilih menu: " M

case $M in
  1) cloudflared login ;;
  2) read -p "Bot Token: " BOT_TOKEN
     sed -i "s|^BOT_TOKEN=.*|BOT_TOKEN=$BOT_TOKEN|" "$ENV" ;;
  3) read -p "Chat ID: " CHAT_ID
     sed -i "s|^CHAT_ID=.*|CHAT_ID=$CHAT_ID|" "$ENV" ;;
  4) bash lib/provision.sh ;;
  5) bash lib/domain_manager.sh ;;
  6) column -t -s, data/registry.csv ;;
  0) exit ;;
esac
