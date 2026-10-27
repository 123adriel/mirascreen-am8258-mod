import paramiko
import os

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('192.168.39.22', username='apalazzesi', password='Prum8525')

print("[1] Subiendo archivos locales a la máquina remota...")
sftp = ssh.open_sftp()
sftp.put(r'C:\Users\apalazzesi\.gemini\antigravity-ide\scratch\mirascreen-am8258-mod\src\init\setup-usbrj45.sh', '/tmp/setup-usbrj45.sh')
sftp.put(r'C:\Users\apalazzesi\.gemini\antigravity-ide\scratch\mirascreen-am8258-mod\src\web-ui-modern\index.html', '/tmp/web_modern_index.html')
sftp.close()

build_script = '''#!/bin/bash
set -e
ROOTFS=/tmp/sq_extracted

echo "=== [1] Instalando nueva interfaz gráfica SWF (HDMI) ==="
cp /tmp/custom_ui_jpg.swf $ROOTFS/am7x/case/data/ezcast_background.swf
cp /tmp/custom_ui_jpg.swf $ROOTFS/am7x/case/data/miracast.swf
cp /tmp/custom_ui_jpg.swf $ROOTFS/am7x/case/data/main_customize.swf
cp /tmp/empty_top_bar.swf $ROOTFS/am7x/case/data/Main_top_bar.swf

echo "=== [2] Instalando demonio USB-RJ45 de conexión principal ==="
cp /tmp/setup-usbrj45.sh $ROOTFS/am7x/bin/setup-usbrj45.sh
chmod +x $ROOTFS/am7x/bin/setup-usbrj45.sh

echo "=== [3] Instalando interfaz web moderna en thttpd ==="
cp /tmp/web_modern_index.html $ROOTFS/usr/share/thttpd/html/index.html
chmod 644 $ROOTFS/usr/share/thttpd/html/index.html

echo "=== [4] Configurando /etc/init.d/rcS sin bloqueos ==="
# Limpiar llamadas previas
sed -i '/setup-usbrj45.sh/d' $ROOTFS/etc/init.d/rcS
sed -i '/net_status.json/d' $ROOTFS/etc/init.d/rcS
sed -i '/telnetd/d' $ROOTFS/etc/init.d/rcS

# Agregar inicio de USB-RJ45 y Telnet
cat << 'EOF_RCS' >> $ROOTFS/etc/init.d/rcS

# Conexión principal USB-RJ45 (Ethernet) y acceso Telnet
/am7x/bin/setup-usbrj45.sh &
telnetd -l /bin/sh &
EOF_RCS

echo "=== [5] Asegurando clave de root vacia ==="
sed -i 's|^root:[^:]*:|root::|' $ROOTFS/etc/shadow

echo "=== [6] Empaquetando nuevo SquashFS 3.1 ==="
rm -f /tmp/rootfs_rj45_ui.sqsh
/tmp/mksquashfs3.4 $ROOTFS /tmp/rootfs_rj45_ui.sqsh -le -all-root -noappend

echo "=== [7] Inyectando SquashFS en firmware SPI de 16MB ==="
cp /tmp/fw.bin /tmp/mirascreen_rj45_ui_16M.bin
dd if=/tmp/rootfs_rj45_ui.sqsh of=/tmp/mirascreen_rj45_ui_16M.bin bs=1 seek=1863680 conv=notrunc

FINAL_SIZE=$(stat -c%s "/tmp/mirascreen_rj45_ui_16M.bin")
echo "Tamaño final del binario: $FINAL_SIZE bytes"
'''

print("[2] Ejecutando compilación y empaquetado...")
sftp = ssh.open_sftp()
with sftp.file('/tmp/run_full_build.sh', 'w') as f:
    f.write(build_script)
sftp.close()

stdin, stdout, stderr = ssh.exec_command('chmod +x /tmp/run_full_build.sh && /tmp/run_full_build.sh')
out = stdout.read().decode('utf-8', errors='replace')
err = stderr.read().decode('utf-8', errors='replace')
print(out)
if err:
    print("ERR:", err)

print("[3] Descargando imagen final a Windows...")
os.makedirs(r'C:\Users\apalazzesi\.gemini\antigravity-ide\scratch\mirascreen-am8258-mod\firmware', exist_ok=True)
dest_path = r'C:\Users\apalazzesi\.gemini\antigravity-ide\scratch\mirascreen-am8258-mod\firmware\mirascreen_rj45_ui_16M.bin'

sftp = ssh.open_sftp()
sftp.get('/tmp/mirascreen_rj45_ui_16M.bin', dest_path)
sftp.close()

local_size = os.path.getsize(dest_path)
print(f"Descarga completa: {dest_path} ({local_size} bytes)")

ssh.close()
