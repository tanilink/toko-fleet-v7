#!/bin/bash
set -e

clear
echo "===================================================="
echo "        KASIR FLEET v7 - MASTER INSTALLER"
echo "===================================================="
echo

# ---------- CHECK ROOT ----------
if [ "$EUID" -ne 0 ]; then
  echo "❌ Installer harus dijalankan sebagai root"
  echo "Gunakan: sudo bash install.sh"
  exit 1
fi

# ---------- BASE DIR ----------
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$BASE_DIR/lib"
CFG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

# ---------- OS CHECK ----------
if ! command -v apt >/dev/null; then
  echo "❌ Installer ini khusus VPS Linux (Ubuntu/Debian)"
  exit 1
fi

# ---------- DEPENDENCY ----------
echo "[1/6] Install dependency sistem..."
apt update -y
apt install -y \
  curl \
  wget \
  jq \
  git \
  unzip \
  whiptail \
  procps

# ---------- CLOUDFLARED ----------
echo "[2/6] Install cloudflared..."
if ! command -v cloudflared >/dev/null; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
  dpkg -i cloudflared-linux-amd64.deb
fi

# ---------- FOLDER STRUCTURE ----------
echo "[3/6] Setup struktur folder..."
mkdir -p "$LIB_DIR" "$CFG_DIR" "$DATA_DIR"

# ---------- GLOBAL CONFIG ----------
if [ ! -f "$CFG_DIR/global.env" ]; then
  cat <<EOF > "$CFG_DIR/global.env"
BASE_DOMAIN=kasiron.my.id
EOF
  echo "✔ global.env dibuat"
fi

# ---------- ADMIN CONFIG ----------
if [ ! -f "$CFG_DIR/admin.env" ]; then
  cat <<EOF > "$CFG_DIR/admin.env"
BOT_TOKEN=
CHAT_ID=
EOF
  echo "✔ admin.env dibuat"
fi

# ---------- REGISTRY ----------
if [ ! -f "$DATA_DIR/registry.csv" ]; then
  echo "#toko_id,subdomain,created_at" > "$DATA_DIR/registry.csv"
  echo "✔ registry.csv dibuat"
fi

# ---------- PERMISSION ----------
echo "[4/6] Set permission script..."
chmod +x "$BASE_DIR/dashboard.sh"
chmod +x "$LIB_DIR"/*.sh

# ---------- CLOUDFLARE LOGIN ----------
echo "[5/6] Cek login Cloudflare..."
if [ ! -f "$HOME/.cloudflared/cert.pem" ]; then
  echo
  echo "🔐 Login Cloudflare diperlukan (sekali saja)"
  echo "Browser akan terbuka, silakan login."
  echo
  cloudflared tunnel login
else
  echo "✔ Cloudflare sudah login"
fi

# ---------- FINISH ----------
echo "[6/6] Instalasi selesai"
echo
echo "===================================================="
echo " INSTALL BERHASIL"
echo "===================================================="
echo
echo "Menjalankan dashboard..."
sleep 1

cd "$BASE_DIR"
./dashboard.sh
