#!/bin/bash
set -e

# ==================================================
# Kasir Fleet v7 - Domain Manager (MASTER / VPS)
# Rotate base domain massal semua toko
# ==================================================

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

GLOBAL_ENV="$CFG_DIR/global.env"
REGISTRY="$DATA_DIR/registry.csv"

CF_CERT="$HOME/.cloudflared/cert.pem"

# ---------- LOAD CONFIG ----------
[ -f "$GLOBAL_ENV" ] || {
  echo "❌ config/global.env tidak ditemukan"
  exit 1
}

source "$GLOBAL_ENV"

# ---------- VALIDASI ----------
if [ ! -f "$CF_CERT" ]; then
  echo "❌ Cloudflare belum login"
  echo "➡️  Jalankan: cloudflared tunnel login"
  exit 1
fi

if [ ! -f "$REGISTRY" ]; then
  echo "❌ registry.csv belum ada (belum ada toko)"
  exit 1
fi

ACTION="$1"
NEW_DOMAIN="$2"

if [ "$ACTION" != "switch" ] || [ -z "$NEW_DOMAIN" ]; then
  echo "Usage:"
  echo "  domain_manager.sh switch domain-baru.com"
  exit 1
fi

OLD_DOMAIN="$BASE_DOMAIN"

echo "==============================================="
echo " ROTATE BASE DOMAIN MASSAL"
echo "==============================================="
echo " Domain lama : $OLD_DOMAIN"
echo " Domain baru : $NEW_DOMAIN"
echo

read -rp "Lanjutkan? (y/N): " CONFIRM
[ "$CONFIRM" != "y" ] && exit 0

# ---------- UPDATE GLOBAL ENV ----------
sed -i "s/^BASE_DOMAIN=.*/BASE_DOMAIN=$NEW_DOMAIN/" "$GLOBAL_ENV"

# ---------- PROCESS REGISTRY ----------
TMP_REGISTRY="$(mktemp)"

while IFS=',' read -r TOKO_ID DOMAIN TGL; do
  NEW_FQDN="$TOKO_ID.$NEW_DOMAIN"

  echo "▶ Update DNS: $TOKO_ID → $NEW_FQDN"

  # Route DNS ulang (idempotent)
  cloudflared tunnel route dns "$TOKO_ID" "$NEW_FQDN" >/dev/null 2>&1 || true

  echo "$TOKO_ID,$NEW_FQDN,$TGL" >> "$TMP_REGISTRY"
done < "$REGISTRY"

mv "$TMP_REGISTRY" "$REGISTRY"

echo
echo "✔ Semua toko berhasil dipindahkan ke domain baru"
echo "✔ Tablet tidak perlu login ulang"
echo "✔ Tunnel tetap aktif"
echo
echo "BASE_DOMAIN sekarang: $NEW_DOMAIN"
