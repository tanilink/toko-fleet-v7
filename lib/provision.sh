#!/bin/bash
set -e
source .env
source lib/utils.sh

read -p "Nama Toko   : " NAMA
read -p "Lokasi      : " LOKASI

ID="$(slugify "$NAMA")-$(slugify "$LOKASI")"
DATE=$(date +%F)

mkdir -p installers templates data

sed "s/{{TOKO_ID}}/$ID/g" templates/installer_cabang.sh.tpl > installers/$ID.sh
sed "s/{{TOKO_ID}}/$ID/g" templates/installer_cabang.txt.tpl > installers/$ID.txt

echo "$ID,$ID.$BASE_DOMAIN,$DATE" >> data/registry.csv

send_telegram "installers/$ID.sh"
send_telegram "installers/$ID.txt"

echo "✔ TOKO $ID BERHASIL DIBUAT"
