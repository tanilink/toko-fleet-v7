#!/bin/bash
set -e

echo "======================================"
echo " KASIR FLEET v7 - MASTER INSTALLER"
echo "======================================"

apt update -y
apt install -y curl git jq zip screen

# Cloudflare
if ! command -v cloudflared >/dev/null; then
  curl -fsSL https://pkg.cloudflare.com/install.sh | bash
  apt install -y cloudflared
fi

mkdir -p /opt/kasir-fleet
cd /opt

if [ ! -d kasir-fleet ]; then
  git clone https://github.com/tanilink/Kasir-fleet-v7.git kasir-fleet
fi

cd kasir-fleet
chmod +x *.sh lib/*.sh

echo
echo "✔ INSTALL SELESAI"
echo "▶ Jalankan dashboard dengan perintah:"
echo "   cd /opt/kasir-fleet && ./dashboard.sh"
