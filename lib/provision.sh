#!/bin/bash

# Mendapatkan data toko dan konfigurasi
source ~/.toko/env

# Fungsi untuk melakukan provisioning server
provision_server() {
  echo "Memulai provisioning untuk toko: $TOKO_ID"
  # Menambahkan setup lainnya di sini, misalnya update paket atau instalasi lainnya
  apt update -y && apt upgrade -y
  echo "Provisioning selesai untuk toko: $TOKO_ID"
}

# Menjalankan provisioning
provision_server
