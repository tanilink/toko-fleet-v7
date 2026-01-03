#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_DIR="$BASE_DIR/config"
LIB_DIR="$BASE_DIR/lib"
DATA_DIR="$BASE_DIR/data"

GLOBAL_ENV="$CFG_DIR/global.env"
ADMIN_ENV="$CFG_DIR/admin.env"
REGISTRY="$DATA_DIR/registry.csv"

CF_CERT="$HOME/.cloudflared/cert.pem"

mkdir -p "$CFG_DIR" "$DATA_DIR"

# ---------- LOAD CONFIG ----------
[ -f "$GLOBAL_ENV" ] && source "$GLOBAL_ENV"
[ -f "$ADMIN_ENV" ] && source "$ADMIN_ENV"

clear

cf_status() {
  if [ -f "$CF_CERT" ]; then
    echo "OK"
  else
    echo "BELUM LOGIN"
  fi
}

banner() {
  echo "===================================================="
  echo "        KASIR FLEET v7 - MASTER DASHBOARD"
  echo "===================================================="
  echo " Base Domain : ${BASE_DOMAIN:-BELUM DISET}"
  echo " Cloudflare  : $(cf_status)"
  echo " Bot Token   : ${BOT_TOKEN:+TERSET}${BOT_TOKEN:-BELUM}"
  echo " Chat ID     : ${CHAT_ID:-BELUM DISET}"
  echo "===================================================="

  if [ ! -f "$CF_CERT" ]; then
    echo " ⚠️  PERINGATAN:"
    echo "    Anda BELUM login Cloudflare."
    echo "    Jalankan: cloudflared tunnel login"
    echo "    (Wajib sebelum Create Toko)"
    echo "----------------------------------------------------"
  fi
  echo
}

pause() {
  read -rp "Tekan ENTER untuk lanjut..."
}

need_admin_env() {
  if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "❌ Bot pusat BELUM dikonfigurasi"
    echo "➡️  Silakan set BOT TOKEN & CHAT ID terlebih dahulu"
    pause
    return 1
  fi
  return 0
}

need_cf_login() {
  if [ ! -f "$CF_CERT" ]; then
    echo "❌ Cloudflare BELUM login"
    echo "➡️  Jalankan dulu:"
    echo "    cloudflared tunnel login"
    pause
    return 1
  fi
  return 0
}

# ---------- MENU LOOP ----------
while true; do
  banner
  echo "[01] Set / Ganti Bot Token (BOT PUSAT)"
  echo "[02] Set / Ganti Chat ID (BOT PUSAT)"
  echo "[03] Test Kirim Pesan Bot PUSAT"
  echo "[04] Create Installer Toko (WAJIB)"
  echo "[05] Lihat Daftar Toko"
  echo "[06] Rotate Base Domain Massal"
  echo "[00] Keluar"
  echo
  read -rp "Pilih menu: " MENU
  echo

  case "$MENU" in
  01)
    read -rp "Masukkan BOT TOKEN Telegram: " BOT_TOKEN
    sed -i '/^BOT_TOKEN=/d' "$ADMIN_ENV" 2>/dev/null || true
    echo "BOT_TOKEN=$BOT_TOKEN" >> "$ADMIN_ENV"
    echo "✔ Bot Token disimpan"
    pause
    ;;
  02)
    read -rp "Masukkan CHAT ID Admin: " CHAT_ID
    sed -i '/^CHAT_ID=/d' "$ADMIN_ENV" 2>/dev/null || true
    echo "CHAT_ID=$CHAT_ID" >> "$ADMIN_ENV"
    echo "✔ Chat ID disimpan"
    pause
    ;;
  03)
    need_admin_env || continue
    bash "$LIB_DIR/bot_manager.sh" test
    pause
    ;;
  04)
    need_admin_env || continue
    need_cf_login || continue
    read -rp "Nama Toko   : " NAMA
    read -rp "Lokasi Toko : " LOKASI
    echo
    bash "$LIB_DIR/provision.sh" create "$NAMA" "$LOKASI"
    pause
    ;;
  05)
    if [ ! -f "$REGISTRY" ]; then
      echo "Belum ada toko terdaftar"
    else
      echo "DAFTAR TOKO:"
      echo "----------------------------------"
      column -t -s',' "$REGISTRY"
    fi
    pause
    ;;
  06)
    need_cf_login || continue
    read -rp "Masukkan BASE DOMAIN BARU: " NEWDOM
    [ -z "$NEWDOM" ] && continue
    bash "$LIB_DIR/domain_manager.sh" switch "$NEWDOM"
    pause
    ;;
  00)
    echo "Keluar dashboard."
    exit 0
    ;;
  *)
    echo "Menu tidak valid"
    pause
    ;;
  esac
done
