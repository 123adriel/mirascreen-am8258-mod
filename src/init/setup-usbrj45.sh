#!/bin/sh
# ==============================================================================
# Script de inicio para Adaptador USB-RJ45 (Ethernet) en Actions Micro AM8258
# ==============================================================================

MOD_DIR=/lib/modules/2.6.27.29

echo "[USB-ETH] Cargando controladores USB Host y Ethernet..."

# 1. Cargar controlador USB OTG y Host Controller
if [ -f "$MOD_DIR/am7x_uoc.ko" ]; then
    insmod $MOD_DIR/am7x_uoc.ko
fi

if [ -f "$MOD_DIR/am7x_hcd.ko" ]; then
    insmod $MOD_DIR/am7x_hcd.ko
fi

# 2. Cargar drivers de red USB
if [ -f "$MOD_DIR/cdc_ether.ko" ]; then
    insmod $MOD_DIR/cdc_ether.ko
fi

if [ -f "$MOD_DIR/cdc_subset.ko" ]; then
    insmod $MOD_DIR/cdc_subset.ko
fi

# Pequeña espera para enumeración USB
sleep 2

# 3. Detectar si apareció una interfaz Ethernet (eth0 o usb0)
ETH_IF=""
if ifconfig -a | grep -q "eth0"; then
    ETH_IF="eth0"
elif ifconfig -a | grep -q "usb0"; then
    ETH_IF="usb0"
fi

if [ -n "$ETH_IF" ]; then
    echo "[USB-ETH] Interfaz detectada: $ETH_IF. Levantando DHCP..."
    ifconfig $ETH_IF up
    
    # Iniciar cliente DHCP en background
    if [ -x /sbin/udhcpc ]; then
        udhcpc -i $ETH_IF -b -s /usr/share/udhcpc/default.script &
    fi
else
    echo "[USB-ETH] No se detecto interfaz cableada, manteniendo Wi-Fi activo."
fi

# 4. Asegurar Telnet activo para acceso root
if [ -x /usr/sbin/telnetd ]; then
    echo "[SECURITY] Iniciando Telnet daemon..."
    telnetd -l /bin/sh &
fi
