#!/bin/bash
set -e

# ==================================================
# KASIR FLEET v7 - DOMAIN MANAGER (FINAL)
# ROTATE BASE DOMAIN MASSAL
# ==================================================

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/data"

source "$CFG_DIR/global.env"

REGISTRY="$DATA_DIR/registry.csv"

[ ! -f "$REGISTRY" ] && {
  echo "❌ registry.csv tidak ditemukan"
  exit 1
}

CMD="$1"
NEW_DOMAIN="$2"

case "$CMD" in
switch)
  [ -z "$NEW_DOMAIN" ] && {
    echo "❌ Base domain baru wajib diisi"
    exit 1
  }

  echo "=============================================="
  echo " ROTATE DOMAIN MASSAL"
  echo "=============================================="
  echo " Domain lama : $BASE_DOMAIN"
  echo " Domain baru : $NEW_DOMAIN"
  echo "=============================================="
  echo

  read -rp "LANJUTKAN? (y/N): " yn
  [[ "$yn" =~ ^[Yy]$ ]] || exit 0

  while IFS=',' read -r TOKO_ID OLD_DOMAIN CREATED; do
    [[ "$TOKO_ID" == \#* ]] && continue
    [ -z "$TOKO_ID" ] && continue

    SUBDOMAIN="${TOKO_ID}"
    NEW_FQDN="$SUBDOMAIN.$NEW_DOMAIN"

    echo "▶ Update: $NEW_FQDN"

    # Hapus route lama (jika ada)
    cloudflared tunnel route dns "$TOKO_ID" "$NEW_FQDN" \
      2>/dev/null || true
  done < "$REGISTRY"

  # Update registry domain
  sed -i "s/\\.$BASE_DOMAIN/.$NEW_DOMAIN/g" "$REGISTRY"

  # Update global config
  sed -i "s/^BASE_DOMAIN=.*/BASE_DOMAIN=$NEW_DOMAIN/" "$CFG_DIR/global.env"

  echo
  echo "✔ ROTATE DOMAIN SELESAI"
  echo "✔ Semua toko sekarang pakai .$NEW_DOMAIN"
  echo
  ;;
list)
  column -t -s',' "$REGISTRY"
  ;;
*)
  echo "Usage:"
  echo "  domain_manager.sh switch domain-baru.com"
  echo "  domain_manager.sh list"
  ;;
esac
