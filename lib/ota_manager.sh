#!/bin/bash
set -e

# ==================================================
# KASIR FLEET v7 - OTA UPDATE MANAGER (FINAL)
# ==================================================

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="$BASE_DIR/config"

source "$CFG_DIR/global.env"
source "$CFG_DIR/admin.env"

REPO_URL="$REPO_URL"   # wajib ada di global.env
TMP_DIR="/tmp/kasir-ota"

send() {
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" -d text="$1" >/dev/null
}

echo "=============================================="
echo " OTA UPDATE - CABANG"
echo "=============================================="
echo " Repo : $REPO_URL"
echo "=============================================="
echo

read -rp "LANJUTKAN OTA UPDATE KE SEMUA CABANG? (y/N): " yn
[[ "$yn" =~ ^[Yy]$ ]] || exit 0

send "🚀 OTA UPDATE DIMULAI"

rm -rf "$TMP_DIR"
git clone "$REPO_URL" "$TMP_DIR" >/dev/null 2>&1 || {
  send "❌ Gagal clone repo"
  exit 1
}

INSTALLERS=$(ls "$TMP_DIR/installers" 2>/dev/null || true)

[ -z "$INSTALLERS" ] && {
  send "❌ Tidak ada installer cabang ditemukan"
  exit 1
}

for f in $INSTALLERS; do
  TOKO="${f%.sh}"
  echo "▶ Update: $TOKO"
  send "🔄 OTA update: $TOKO"

  curl -fsSL "$REPO_URL/raw/main/installers/$f" | bash || {
    send "❌ OTA gagal: $TOKO"
    continue
  }

  send "✅ OTA sukses: $TOKO"
done

send "✅ OTA UPDATE SELESAI"
