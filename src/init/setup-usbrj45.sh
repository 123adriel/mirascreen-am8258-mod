#!/bin/sh
# Inicialización de Hardware USB OTG + Adaptador RJ45 (CDC Ethernet)
# Plataforma: Actions Micro AM8258 - Linux 2.6.27.29

MOD_DIR="/lib/modules/2.6.27.29"
STATUS_FILE="/tmp/net_status.json"

# 1. Cargar pila USB OTG, Host Controller y driver CDC Ethernet
insmod "$MOD_DIR/am7x_uoc.ko" 2>/dev/null
sleep 1
insmod "$MOD_DIR/am7x_hcd.ko" 2>/dev/null
sleep 1
insmod "$MOD_DIR/cdc_ether.ko" 2>/dev/null

# Opcional: Si probás adaptadores basados en ASIX (AX88772) o Realtek (RTL8152)
# y tenés los módulos compilados en el árbol, se intentan cargar:
[ -f "$MOD_DIR/asix.ko" ] && insmod "$MOD_DIR/asix.ko" 2>/dev/null
[ -f "$MOD_DIR/usbnet.ko" ] && insmod "$MOD_DIR/usbnet.ko" 2>/dev/null

# 2. Levantar acceso root por Telnet inmediatamente
telnetd -l /bin/sh &

# 3. Bucle de vigilancia en segundo plano para detectar eth0 y actualizar la UI
(
  while true; do
    if grep -q "eth0:" /proc/net/dev; then
      ifconfig eth0 up 2>/dev/null
      ETH_IP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
      
      if [ -z "$ETH_IP" ]; then
        # Solicitar IP por DHCP si aún no tiene una asignada
        udhcpc -i eth0 -n -q -t 3 2>/dev/null
        ETH_IP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
      fi

      if [ -n "$ETH_IP" ]; then
        echo "{\"mode\":\"ETH\",\"ip\":\"$ETH_IP\",\"iface\":\"eth0\"}" > "$STATUS_FILE"
      else
        echo "{\"mode\":\"WAIT_DHCP\",\"ip\":\"192.168.49.1\",\"iface\":\"eth0\"}" > "$STATUS_FILE"
      fi
    else
      echo "{\"mode\":\"SOFTAP\",\"ip\":\"192.168.49.1\",\"iface\":\"wlan0\"}" > "$STATUS_FILE"
    fi
    sleep 5
  done
) &
