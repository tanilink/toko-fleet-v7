#!/bin/bash
set -e

echo "======================================="
echo " KASIR FLEET v7 - INSTALLER CABANG"
echo " TOKO : {{TOKO_ID}}"
echo "======================================="

pkg update -y
pkg install -y curl jq zip termux-api procps

termux-wake-lock
termux-setup-storage

mkdir -p ~/.toko/logs ~/.termux/boot

cat > ~/.toko/env <<EOF
TOKO_ID="{{TOKO_ID}}"
PORT=7575
EOF

cat > ~/.toko/start.sh <<'EOS'
#!/bin/bash
termux-wake-lock
# di sini nanti server kasir kamu
EOS

chmod +x ~/.toko/*.sh
ln -sf ~/.toko/start.sh ~/.termux/boot/start.sh

echo "✔ TOKO ONLINE"
