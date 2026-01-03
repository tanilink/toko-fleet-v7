#!/bin/bash
set -e

echo "==============================================="
echo " KASIR FLEET v7 - MASTER INSTALLER"
echo "==============================================="
echo

# ---------- CEK SCREEN ----------
if [ -z "$STY" ]; then
  echo "⚠️  Installer HARUS dijalankan di dalam screen"
  echo
  echo "Gunakan perintah:"
  echo "  screen -S kasir-setup"
  echo "  lalu jalankan:"
  echo "  bash install.sh"
  echo
  exit 1
fi

echo "✔ Screen session terdeteksi"

# ---------- OS DETECTION ----------
if command -v apt >/dev/null 2>&1; then
  OS="ubuntu"
elif command -v pkg >/dev/null 2>&1; then
  OS="termux"
else
  echo "❌ OS tidak dikenali"
  exit 1
fi

echo "✔ OS terdeteksi: $OS"
echo

# ---------- INSTALL DEPENDENCY ----------
echo "▶ Install dependency..."
if [ "$OS" = "ubuntu" ]; then
  sudo apt update -y
  sudo apt install -y git curl jq zip screen
  if ! command -v cloudflared >/dev/null 2>&1; then
    curl -fsSL https://pkg.cloudflare.com/install.sh | sudo bash
    sudo apt install -y cloudflared
  fi
else
  pkg update -y
  pkg install -y git curl jq zip screen cloudflared
fi
echo "✔ Dependency selesai"
echo

# ---------- CLONE / UPDATE REPO ----------
REPO_DIR="$HOME/toko-fleet-v7"

if [ -d "$REPO_DIR/.git" ]; then
  echo "▶ Repo sudah ada, update..."
  cd "$REPO_DIR"
  git pull
else
  echo "▶ Clone repo Kasir Fleet v7..."
  cd "$HOME"
  git clone https://github.com/tanilink/toko-fleet-v7.git
  cd "$REPO_DIR"
fi

echo "✔ Repo siap"
echo

# ---------- PERMISSION ----------
chmod +x dashboard.sh
chmod +x lib/*.sh

# ---------- ALIAS ----------
if ! grep -q "alias admin22=" ~/.bashrc; then
  echo "alias admin22='cd ~/toko-fleet-v7 && bash dashboard.sh'" >> ~/.bashrc
  echo "✔ Alias admin22 dibuat"
fi

# ---------- FINAL ----------
echo
echo "==============================================="
echo " INSTALL SELESAI"
echo "==============================================="
echo
echo "➡️  Jalankan dashboard dengan:"
echo "    admin22"
echo
echo "📌 Jangan tutup screen!"
echo "📌 Detach: Ctrl+A lalu D"
echo

# ---------- JALANKAN DASHBOARD ----------
exec bash dashboard.sh
