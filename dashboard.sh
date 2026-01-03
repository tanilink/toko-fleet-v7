#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$BASE_DIR/lib"
CFG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

# Load config jika ada
[ -f "$CFG_DIR/global.env" ] && source "$CFG_DIR/global.env"
[ -f "$CFG_DIR/admin.env" ] && source "$CFG_DIR/admin.env"

# Default
BASE_DOMAIN="${BASE_DOMAIN:-kasiron.my.id}"

# ---------- UI HELPER ----------
pause() {
  read -rp "Tekan ENTER untuk kembali..."
}

header() {
  clear
  echo "===================================================="
  echo "        KASIR FLEET v7 - MASTER DASHBOARD"
  echo "===================================================="
  echo " Base Domain : $BASE_DOMAIN"
  echo " Bot Token   : ${BOT_TOKEN:+SET}${BOT_TOKEN:-BELUM}"
  echo " Chat ID     : ${CHAT_ID:-BELUM}"
  echo "===================================================="
  echo
}

confirm() {
  read -rp "$1 (y/N): " yn
  [[ "$yn" =~ ^[Yy]$ ]]
}

# ---------- MENU FUNCTIONS ----------

menu_set_bot() {
  while true; do
    header
    echo "[01] Set / Ganti Bot Token"
    echo "[02] Set / Ganti Chat ID"
    echo "[03] Hapus Konfigurasi Bot"
    echo "[04] Test Kirim Pesan Bot"
    echo "[05] Restart Bot Service"
    echo "[00] Kembali"
    echo
    read -rp "Pilih menu: " c

    case "$c" in
      1)
        read -rp "Masukkan BOT TOKEN: " BOT_TOKEN
        sed -i "s|^BOT_TOKEN=.*|BOT_TOKEN=$BOT_TOKEN|" "$CFG_DIR/admin.env"
        echo "✔ Bot token disimpan"
        pause
        ;;
      2)
        read -rp "Masukkan CHAT ID ADMIN: " CHAT_ID
        sed -i "s|^CHAT_ID=.*|CHAT_ID=$CHAT_ID|" "$CFG_DIR/admin.env"
        echo "✔ Chat ID disimpan"
        pause
        ;;
      3)
        confirm "Yakin hapus konfigurasi bot?" && {
          sed -i "s|^BOT_TOKEN=.*|BOT_TOKEN=|" "$CFG_DIR/admin.env"
          sed -i "s|^CHAT_ID=.*|CHAT_ID=|" "$CFG_DIR/admin.env"
          echo "✔ Konfigurasi bot dihapus"
        }
        pause
        ;;
      4)
        bash "$LIB_DIR/bot_manager.sh" test
        pause
        ;;
      5)
        bash "$LIB_DIR/bot_manager.sh" restart
        pause
        ;;
      0) return ;;
    esac
  done
}

menu_create_toko() {
  header
  read -rp "Nama Toko   : " NAMA
  read -rp "Lokasi Toko : " LOKASI

  bash "$LIB_DIR/provision.sh" create "$NAMA" "$LOKASI" "$BASE_DOMAIN"
  pause
}

menu_list_toko() {
  header
  if [ ! -s "$DATA_DIR/registry.csv" ]; then
    echo "Belum ada toko terdaftar."
    pause
    return
  fi

  echo "DAFTAR TOKO:"
  echo "---------------------------------------------"
  column -t -s',' "$DATA_DIR/registry.csv"
  echo "---------------------------------------------"
  pause
}

menu_operasional() {
  header
  echo "[01] Kirim Status Semua Toko"
  echo "[02] Backup Toko (via Bot)"
  echo "[03] Kirim Summary Manual"
  echo "[00] Kembali"
  echo
  read -rp "Pilih menu: " c

  case "$c" in
    1) bash "$LIB_DIR/bot_manager.sh" status ;;
    2) bash "$LIB_DIR/bot_manager.sh" backup ;;
    3) bash "$LIB_DIR/bot_manager.sh" summary ;;
  esac
  pause
}

menu_health() {
  header
  bash "$LIB_DIR/health_check.sh"
  pause
}

menu_domain_switch() {
  header
  echo "Base domain saat ini : $BASE_DOMAIN"
  echo
  read -rp "Masukkan BASE DOMAIN BARU: " NEW_DOMAIN

  confirm "Ganti SEMUA toko ke $NEW_DOMAIN ?" && {
    bash "$LIB_DIR/domain_manager.sh" switch "$NEW_DOMAIN"
    sed -i "s|^BASE_DOMAIN=.*|BASE_DOMAIN=$NEW_DOMAIN|" "$CFG_DIR/global.env"
    BASE_DOMAIN="$NEW_DOMAIN"
    echo "✔ Base domain berhasil diganti"
  }
  pause
}

# ---------- MAIN LOOP ----------
while true; do
  header
  echo "[01] Set Bot Telegram"
  echo "[02] Create Toko / Installer"
  echo "[03] Daftar Toko"
  echo "[04] Operasional (via Bot)"
  echo "[05] Health Check"
  echo "[06] Ganti Base Domain Global"
  echo "[00] Exit"
  echo
  read -rp "Pilih menu: " menu

  case "$menu" in
    1) menu_set_bot ;;
    2) menu_create_toko ;;
    3) menu_list_toko ;;
    4) menu_operasional ;;
    5) menu_health ;;
    6) menu_domain_switch ;;
    0) clear; exit 0 ;;
  esac
done
