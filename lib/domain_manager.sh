#!/bin/bash

# Mendapatkan data toko dan domain dari file konfigurasi
source ~/.toko/env

# Fungsi untuk mengganti domain
change_domain() {
  echo "Mengganti domain menjadi $1"
  FULL_DOMAIN="$TOKO_ID.$1"
  cloudflared tunnel route dns "$TOKO_ID" "$FULL_DOMAIN"
  echo "Domain berhasil diganti: $FULL_DOMAIN"
}

# Fungsi untuk menambah domain ke daftar domain
add_domain_to_list() {
  DOMAIN="$1"
  echo "$DOMAIN" >> ~/.toko/config/domains.list
  echo "Domain $DOMAIN berhasil ditambahkan ke daftar."
}

# Menambahkan opsi untuk mengganti atau menambah domain
case "$1" in
  change)
    change_domain "$2"
    ;;
  add)
    add_domain_to_list "$2"
    ;;
  *)
    echo "Perintah tidak valid. Gunakan 'change' untuk mengganti domain atau 'add' untuk menambah domain."
    ;;
esac
