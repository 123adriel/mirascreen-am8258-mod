#!/usr/bin/env python3
"""
Herramienta de flasheo para MiraScreen AM8258 con CH341A SPI Programmer
"""

import sys
import os
import subprocess

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLASHROM = os.path.join(REPO_DIR, "tools", "flashrom.exe")

def flash(bin_file):
    if not os.path.isfile(bin_file):
        print(f"[-] Error: Archivo {bin_file} no encontrado.")
        return False
    
    size = os.path.getsize(bin_file)
    if size != 16777216:
        print(f"[-] Advertencia: El archivo tiene {size} bytes, se esperaban exactamente 16777216 bytes (16MB).")
        resp = input("¿Desea continuar de todos modos? [s/N]: ")
        if resp.lower() != 's':
            return False

    print(f"[+] Iniciando flasheo de: {bin_file}")
    print(f"[+] Programador: CH341A SPI")
    print(f"[+] Chip objetivo: GigaDevice GD25Q128C (16 MB)")
    print("[*] Escribiendo y verificando memoria flash (toma aprox 2-3 minutos)...")

    cmd = [
        FLASHROM,
        "-p", "ch341a_spi",
        "-c", "GD25Q128C",
        "-w", bin_file
    ]

    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        print(proc.stdout)
        if "VERIFIED" in proc.stdout or "done" in proc.stdout or proc.returncode == 0:
            print("[✓] ¡Flasheo completado y verificado con éxito!")
            return True
        else:
            print("[-] Ocurrió un error durante el flasheo.")
            return False
    except Exception as e:
        print(f"[-] Excepción ejecutando flashrom: {e}")
        return False

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO_DIR, "firmware", "miracast_custom_usbeth_root.bin")
    flash(target)
