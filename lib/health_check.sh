#!/bin/bash

# Mendapatkan data toko dan konfigurasi
source ~/.toko/env

# Fungsi untuk memeriksa kesehatan sistem
health_check() {
  BATTERY=$(termux-battery-status | jq -r '.percentage')
  if [ "$BATTERY" -lt 10 ]; then
    echo "⚠️ Peringatan: Baterai rendah ($BATTERY%)"
    send_message "⚠️ Baterai rendah di $TOKO_ID: $BATTERY%"
  fi
  echo "Kesehatan sistem OK. Baterai: $BATTERY%"
}

# Menjalankan pemeriksaan kesehatan setiap 5 menit
while true; do
  health_check
  sleep 300
done
