#!/bin/bash
source .env

read -p "Base domain baru: " NEW

sed -i "s|BASE_DOMAIN=.*|BASE_DOMAIN=$NEW|" .env

while IFS=, read ID DOMAIN DATE; do
  cloudflared tunnel route dns "$ID.$NEW" kasir-fleet || true
done < data/registry.csv

echo "✔ DOMAIN DIGANTI KE $NEW"
