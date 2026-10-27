# MiraScreen AM8258 - Custom Firmware & Hardware Modding

Repositorio de ingeniería inversa, modificación de firmware, soporte para adaptador **USB a RJ45 (Ethernet directo como conexión principal)** y rediseño de interfaz de usuario (HDMI OSD + Web) para receptores **MiraScreen / AnyCast** basados en el procesador **Actions Micro AM8258**.

---

## 1. Ficha Técnica del Dispositivo

| Componente | Especificación |
| :--- | :--- |
| **SoC** | Actions Micro AM8258 (CPU MIPS32 rel2, Little-Endian) |
| **Memoria Flash** | GigaDevice `GD25Q128` (16 MByte / 128 Mbit SPI NOR Flash) |
| **Memoria RAM** | DDR2 (calibración automática 64MB / 128MB) |
| **Kernel** | Linux `2.6.27.29` (plataforma Actions AM7x) |
| **Root Filesystem** | SquashFS v3.1 (ZLIB, offset `0x1C7000`) |
| **Controlador Wi-Fi** | Realtek RTL8188FU / RTL8192 (`8188fu.ko`) |
| **Interfaz Gráfica OSD** | Macromedia Flash SWF decodificado por `fui.app` + `libswfdec.so` |

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

## 3. Conexión USB a RJ45 como Red Principal

El dispositivo utiliza el puerto micro-USB en modo Host mediante un **cable OTG en "Y"** (con inyección de 5V):

1. **Carga no bloqueante de controladores:**
   Para evitar colisiones de bus en el arranque con el módulo Wi-Fi `8188fu.ko` (que provocaba el cuelgue en "Buscando SSID"), el demonio `/am7x/bin/setup-usbrj45.sh` espera la inicialización previa de `manager.app` y luego inserta:
   * `am7x_uoc.ko`: Controlador USB OTG.
   * `am7x_hcd.ko`: USB Host Controller.
   * `cdc_ether.ko` / `cdc_subset.ko`: Controlador USB CDC Ethernet.
2. **Priorización de Tráfico (Default Gateway):**
   Al detectar la interfaz `eth0` / `usb0`, solicita arrendamiento por DHCP (`udhcpc`) y asigna la ruta predeterminada con métrica 0 para que todo el tráfico transcurra prioritariamente por el cable Ethernet.

---

## 4. Nueva Interfaz Gráfica (HDMI On-Screen Display + Web)

Se rediseñó completamente la interfaz en pantalla reemplazando los assets SWF originales del motor `fui.app`:
* **Paso 1:** Ilustración con teclas **Windows + K**.
* **Paso 2:** Estado de conexión **Mirascreen BFDA3480** con indicador dinámico *"Listo para conectar"*.
* Los archivos SWF generados a 1080p (`ezcast_background.swf`, `miracast.swf`, `main_customize.swf`) muestran la nueva estética glassmorphism tanto en la TV como en el servidor web (`/usr/share/thttpd/html/index.html`).

---

## 5. Acceso Root por Telnet

* **Puerto:** 23 (Telnet estándar)
* **Usuario:** `root` (sin contraseña)
* Se inicia automáticamente al arrancar tanto por Ethernet cableada como por Wi-Fi.

---

## 6. Flasheo del Firmware Modificado

Para flashear el binario final de 16 MB con el programador CH341A:

```bash
python tools/flash_firmware.py firmware/mirascreen_rj45_ui_16M.bin
```
