# MiraScreen AM8258 - Custom Firmware & Hardware Modding

Repositorio de ingeniería inversa, modificación de firmware, soporte para adaptador **USB a RJ45 (Ethernet directo)** y rediseño de interfaz de usuario para receptores **MiraScreen / AnyCast** basados en el procesador **Actions Micro AM8258**.

---

## 1. Ficha Técnica del Dispositivo

| Componente | Especificación |
| :--- | :--- |
| **SoC** | Actions Micro AM8258 (CPU MIPS32 rel2, Little-Endian) |
| **Memoria Flash** | GigaDevice `GD25Q128` (16 MByte / 128 Mbit SPI NOR Flash) |
| **Memoria RAM** | DDR2 (calibración automática 64MB / 128MB) |
| **Kernel** | Linux `2.6.27.29` (plataforma Actions AM7x) |
| **Root Filesystem** | SquashFS v3.1 (ZLIB, offset `0x1C7000`) |
| **Controlador Wi-Fi** | Realtek RTL8188FU / RTL8192 (`rtl871xdrv.ko`) |
| **Consola UART** | `ttyS0` a **115200 8N1** (Niveles lógicos 3.3V) |

---

## 2. Mapa de Memoria Flash (16 MB SPI)

```text
[0x00000000 - 0x00012FFF]  Bootloader MultiSectorBoot & Parámetros DDR
[0x00013000 - 0x001C6FFF]  Kernel Linux comprimido (gzip vmlinux)
[0x001C7000 - 0x00F72FFF]  Root Filesystem (SquashFS 3.1)
[0x00F73000 - 0x00F7FFFF]  Configuraciones persistentes (VRAM / hostapd / ezcast.conf)
[0x00F80000 - 0x00FFFFFF]  Particiones adicionales de usuario y buffers
```

---

## 3. Credenciales y Red de Fábrica

* **SSID Wi-Fi (SoftAP):** `Mirascreen BFDA3480`
* **Contraseña WPA2:** `67661126`
* **IP Gateway:** `192.168.49.1`
* **Usuario del Sistema:** `root`
* **Hash en `/etc/shadow`:** `$1$EIYYGRBK$inOu3EFhrsNF0FzaGDozn.`

---

## 4. Conexión USB a RJ45 (Ethernet Directo)

El puerto micro-USB del dongle no solo sirve para energía; el SoC AM8258 cuenta con un controlador **USB OTG** completo. 

El firmware original incluye los siguientes módulos de kernel en `/lib/modules/2.6.27.29/`:
* `am7x_uoc.ko`: Controlador USB OTG.
* `am7x_hcd.ko`: Host Controller Driver (para alimentar y controlar periféricos USB).
* `cdc_ether.ko`: Controlador para adaptadores de red Ethernet USB compatibles con el estándar CDC.

### Inicialización Automática
En `src/init/setup-usbrj45.sh` se encuentra el script que carga los módulos y levanta la interfaz cableada (`eth0`) con cliente DHCP:
```sh
insmod /lib/modules/2.6.27.29/am7x_uoc.ko
insmod /lib/modules/2.6.27.29/am7x_hcd.ko
insmod /lib/modules/2.6.27.29/cdc_ether.ko
udhcpc -i eth0 -b &
telnetd -l /bin/sh &
```

Al utilizar un cable **OTG en "Y"** (con entrada de alimentación de 5V para alimentar tanto el MiraScreen como el adaptador RJ45), el dispositivo se conecta directamente a tu red local por cable.

---

## 5. Acceso Root Inmediato

1. **Por Telnet en Red:**
   ```bash
   # Vía Wi-Fi SoftAP
   telnet 192.168.49.1

   # Vía Ethernet Cableada
   telnet 192.168.1.150
   ```
2. **Por UART Físico:**
   * Pines `TX`, `RX` y `GND` de la placa conectados a 3.3V.
   * `115200 baudios, 8 bits de datos, sin paridad, 1 bit de parada`.

---

## 6. Nueva Interfaz Web Moderna (`src/web-ui-modern/`)

La interfaz original de fábrica (ubicada en `src/web-ui/`) fue creada en 2014 con jQuery arcaico. 
Se desarrolló un nuevo panel de control moderno en `src/web-ui-modern/`:
* **Tema Oscuro & Glassmorphism:** Diseñado con CSS moderno, efectos visuales de desenfoque y tipografía Inter.
* **Control Integral de Red:** Cambio entre DHCP y configuración de IP fija para el adaptador RJ45.
* **Ajuste de Salida HDMI:** Selector rápido de resolución (1080p60, 1080p30, 720p).
* **Consola de Comandos y Herramientas:** Accesos directos para Telnet, reinicio y restablecimiento.

---

## 7. Herramientas del Repositorio

* **`firmware/miracast_stock_16M.bin`**: Copia original y limpia del volcado de 16 MB.
* **`tools/flashrom.exe`**: Versión compilada y parcheada de flashrom para CH341A que omite el falso error de paridad de GigaDevice.
* **`tools/flash_firmware.py`**: Script en Python para flashear cualquier imagen directamente al chip SPI:
  ```bash
  python tools/flash_firmware.py firmware/miracast_stock_16M.bin
  ```
