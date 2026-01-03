#!/bin/bash
clear
echo "========================================"
echo " TOKO FLEET v7 - MASTER INSTALLER"
echo "========================================"
if [ "$EUID" -ne 0 ]; then
  echo "Jalankan dengan sudo"
  exit 1
fi
apt update -y && apt install -y curl wget jq git whiptail
if ! command -v cloudflared >/dev/null; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
  dpkg -i cloudflared-linux-amd64.deb
fi
mkdir -p lib config data
[ ! -f config/global.env ] && echo "BASE_DOMAIN=kasiron.my.id" > config/global.env
[ ! -f config/admin.env ] && echo -e "BOT_TOKEN=\nCHAT_ID=" > config/admin.env
[ ! -f "$HOME/.cloudflared/cert.pem" ] && cloudflared tunnel login
chmod +x dashboard.sh lib/*.sh
./dashboard.sh
