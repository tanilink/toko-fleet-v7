# TOKO FLEET v7

TUI Dashboard version

Ubuntu
 screen -S kasir-setup bash -c 'sudo apt update -y && sudo apt install -y screen git curl jq zip && git clone https://github.com/tanilink/toko-fleet-v7.git && cd Kasir-fleet-v7 && bash dashboard.sh'

Termux
screen -S kasir-setup bash -c 'pkg update -y && pkg install -y screen git curl jq zip cloudflared && git clone https://github.com/tanilink/toko-fleet-v7.git && cd Kasir-fleet-v7 && bash dashboard.sh'

Kalo Putus
screen -r kasir-setup

Keluar tanpa mematikan proses
Ctrl + A lalu D
