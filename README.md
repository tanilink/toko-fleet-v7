# 🚀 Kasir Fleet v7  
### Sistem Manajemen Kasir Multi-Cabang (Cloudflare + Telegram Bot)

Kasir Fleet v7 adalah sistem **fleet management** untuk tablet kasir multi-cabang berbasis **Termux**, **Cloudflare Tunnel**, dan **Telegram Bot**.

Dirancang untuk:
- UMKM dengan banyak cabang
- Operasional lapangan (tablet Android)
- Admin pusat yang ingin kontrol penuh tanpa datang ke toko

> ⚠️ **Catatan**  
> Repo ini ditujukan untuk **admin & teknisi**, **bukan operator kasir**.

---

## ✨ Fitur Utama

- 🔒 **Cloudflare Tunnel Stabil**
  - Watchdog auto-restart
  - Anti proses dobel (lock system)

- 🤖 **Telegram Bot Operasional**
  - `/nyala`, `/mati`, `/status`
  - Kontrol penuh dari pusat

- 📦 **Backup Database via Bot**
  - Pilih database
  - Kirim ZIP langsung ke Telegram

- 🔄 **OTA Update Cabang**
  - Update tablet tanpa datang ke toko
  - Aman & idempotent

- 🌐 **Rotate Domain Massal**
  - Ganti base domain semua toko sekaligus
  - Tanpa login ulang Cloudflare di tablet

---

## 🧱 Arsitektur Sistem

[VPS / Termux Admin]
├─ Dashboard (TUI)
├─ Provisioner (Create Toko)
├─ Cloudflare Account
└─ Telegram Bot (Admin)
│
│ installer.sh
▼
[Tablet Cabang (Termux)]
├─ start.sh (nyala tunnel)
├─ watchdog.sh (auto-restart)
├─ bot.sh (kontrol)
├─ backup.sh (backup DB)
└─ server kasir


---

## 🚀 Instalasi Admin (VPS / Termux)  
### (Satu Perintah – Aman Jika Koneksi Terputus)

### 🔹 Termux (Admin Android)
screen -S kasir-setup bash -c 'pkg update -y && pkg install -y screen git curl jq zip cloudflared && git clone https://github.com/tanilink/toko-fleet-v7.git && cd Kasir-fleet-v7 && bash dashboard.sh' 

### Jika koneksi terputus:
screen -r kasir-setup

### 🔹 Ubuntu / VPS
screen -S kasir-setup bash -lc 'command -v git >/dev/null || (apt update -y && apt install -y git curl jq zip screen); command -v cloudflared >/dev/null || (curl -fsSL https://pkg.cloudflare.com/install.sh | bash && apt install -y cloudflared); cd ~; [ -d toko-fleet-v7 ] || git clone https://github.com/tanilink/toko-fleet-v7.git; cd toko-fleet-v7; chmod +x install.sh; bash install.sh; exec bash'
