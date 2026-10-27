#!/bin/sh
# Inicialización de Hardware USB OTG + Adaptador RJ45 (CDC Ethernet)
# Plataforma: Actions Micro AM8258 - Linux 2.6.27.29

MOD_DIR="/lib/modules/2.6.27.29"
STATUS_FILE="/tmp/net_status.json"

# Esperar 3 segundos para que manager.app y el driver de Wi-Fi inicialicen
# sin colisiones de bus ni bloqueos en 'Buscando SSID'
sleep 3

# 1. Cargar pila USB OTG, Host Controller y driver CDC Ethernet
insmod "$MOD_DIR/am7x_uoc.ko" 2>/dev/null
sleep 1
insmod "$MOD_DIR/am7x_hcd.ko" 2>/dev/null
sleep 1
insmod "$MOD_DIR/cdc_ether.ko" 2>/dev/null
insmod "$MOD_DIR/cdc_subset.ko" 2>/dev/null

# Intentar otros drivers Ethernet USB comunes si estuvieran presentes
[ -f "$MOD_DIR/rndis_host.ko" ] && insmod "$MOD_DIR/rndis_host.ko" 2>/dev/null
[ -f "$MOD_DIR/asix.ko" ] && insmod "$MOD_DIR/asix.ko" 2>/dev/null

# 2. Levantar acceso root por Telnet
telnetd -l /bin/sh &

# 3. Bucle de vigilancia en segundo plano para asegurar RJ45 como conexión PRINCIPAL
(
  while true; do
    ETH_DEV=""
    if grep -q "eth0:" /proc/net/dev 2>/dev/null || [ -d /sys/class/net/eth0 ]; then
      ETH_DEV="eth0"
    elif grep -q "usb0:" /proc/net/dev 2>/dev/null || [ -d /sys/class/net/usb0 ]; then
      ETH_DEV="usb0"
    elif grep -q "usb1:" /proc/net/dev 2>/dev/null || [ -d /sys/class/net/usb1 ]; then
      ETH_DEV="usb1"
    fi

    if [ -n "$ETH_DEV" ]; then
      ifconfig $ETH_DEV up 2>/dev/null
      ETH_IP=$(ifconfig $ETH_DEV | awk '/inet addr/{print substr($2,6)}')

      if [ -z "$ETH_IP" ]; then
        # Solicitar IP por DHCP en segundo plano
        udhcpc -i $ETH_DEV -n -q -t 4 2>/dev/null
        ETH_IP=$(ifconfig $ETH_DEV | awk '/inet addr/{print substr($2,6)}')
      fi

      if [ -n "$ETH_IP" ]; then
        # Asegurar ruta por defecto preferencial en la interfaz RJ45
        route add default dev $ETH_DEV metric 0 2>/dev/null
        
        echo "$ETH_IP" > /tmp/rj45_ip.txt
        touch /tmp/usbrj45_connected

        cat << EOF > "$STATUS_FILE"
{
  "mode": "RJ45_PRIMARY",
  "status": "connected",
  "iface": "$ETH_DEV",
  "ip": "$ETH_IP",
  "target": "Mirascreen BFDA3480"
}
EOF
      else
        cat << EOF > "$STATUS_FILE"
{
  "mode": "RJ45_WAIT_DHCP",
  "status": "connecting",
  "iface": "$ETH_DEV",
  "ip": "0.0.0.0",
  "target": "Mirascreen BFDA3480"
}
EOF
      fi
    else
      cat << EOF > "$STATUS_FILE"
{
  "mode": "WAIT_RJ45_ADAPTER",
  "status": "disconnected",
  "iface": "none",
  "ip": "192.168.49.1",
  "target": "Mirascreen BFDA3480"
}
EOF
    fi

    sleep 5
  done
) &
