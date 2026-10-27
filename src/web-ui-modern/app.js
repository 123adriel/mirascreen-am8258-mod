// App logic and CGI integration for MiraScreen AM8258 Modern UI

document.addEventListener('DOMContentLoaded', () => {
  setupTabs();
  setupResolutions();
});

// Tab navigation
function setupTabs() {
  const tabs = document.querySelectorAll('.tab-btn');
  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

      btn.classList.add('active');
      const targetId = btn.getAttribute('data-tab');
      const targetContent = document.getElementById(targetId);
      if (targetContent) {
        targetContent.classList.add('active');
      }
    });
  });
}

// Resolution radio cards
function setupResolutions() {
  const cards = document.querySelectorAll('.res-card');
  cards.forEach(card => {
    card.addEventListener('click', () => {
      cards.forEach(c => c.classList.remove('active'));
      card.classList.add('active');
      const radio = card.querySelector('input[type="radio"]');
      if (radio) radio.checked = true;
    });
  });
}

function toggleIpInputs() {
  const mode = document.getElementById('rj45-mode').value;
  const staticFields = document.getElementById('static-ip-fields');
  if (mode === 'static') {
    staticFields.classList.remove('hidden');
  } else {
    staticFields.classList.add('hidden');
  }
}

// Toast notification
function showToast(msg) {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.classList.add('show');
  setTimeout(() => {
    toast.classList.remove('show');
  }, 3500);
}

function copyCode(text) {
  navigator.clipboard.writeText(text).then(() => {
    showToast('Copiado al portapapeles: ' + text);
  });
}

// Actions
function saveEthernetConfig() {
  const mode = document.getElementById('rj45-mode').value;
  const ip = document.getElementById('rj45-ip').value;
  
  showToast(mode === 'dhcp' ? 'Configuración Ethernet guardada (DHCP)' : `IP Estática guardada: ${ip}`);
  document.getElementById('eth-status').textContent = mode === 'dhcp' ? 'Conectado (DHCP)' : 'Estática';
  document.getElementById('eth-ip').textContent = `IP: ${ip}`;
}

function restartEthernetService() {
  showToast('Reiniciando interfaz de red eth0...');
}

function saveWifiConfig() {
  const ssid = document.getElementById('ap-ssid').value;
  const pass = document.getElementById('ap-pass').value;

  // Enviar a CGI oficial si está en vivo
  fetch(`/cgi-bin/set_wifi_POST.cgi?ssid=${encodeURIComponent(ssid)}&password=${encodeURIComponent(pass)}`)
    .then(r => r.text())
    .then(data => {
      showToast('Configuración Wi-Fi actualizada');
      document.getElementById('wifi-ssid').textContent = ssid;
    })
    .catch(() => {
      // Modo offline / demostración
      showToast(`Wi-Fi guardado: ${ssid} / clave: ${pass}`);
      document.getElementById('wifi-ssid').textContent = ssid;
    });
}

function applyResolution() {
  const selected = document.querySelector('input[name="res"]:checked').value;
  
  fetch(`/cgi-bin/set_resolution_POST.cgi?resolution=${selected}`)
    .then(r => r.text())
    .then(() => showToast(`Resolución cambiada a ${selected}`))
    .catch(() => showToast(`Resolución aplicada: ${selected}`));
}

function rebootDevice() {
  if (confirm('¿Desea reiniciar el adaptador MiraScreen ahora?')) {
    fetch('/cgi-bin/set_devicename_reboot.cgi')
      .finally(() => showToast('Enviada señal de reinicio al sistema...'));
  }
}

function factoryReset() {
  if (confirm('ATENCIÓN: ¿Restablecer el dongle a valores de fábrica?')) {
    fetch('/cgi-bin/factory_test.cgi?cmd=reset')
      .finally(() => showToast('Restableciendo valores de fábrica...'));
  }
}
