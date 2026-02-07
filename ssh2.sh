#!/usr/bin/env bash

# ===============================
# AUTO-SUDO
# ===============================
if [[ $EUID -ne 0 ]]; then
  echo "🔐 Reexecutando com sudo..."
  exec sudo bash "$0" "$@"
fi

echo "✅ Executando como root"

# ===============================
# DETECTAR DISTRO
# ===============================
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
else
  echo "❌ Não foi possível detectar a distro"
  exit 1
fi

echo "🧠 Distro detectada: $DISTRO"

# ===============================
# VERIFICAR INTERNET
# ===============================
echo "🌐 Verificando internet..."
ping -c 1 -W 3 8.8.8.8 >/dev/null || {
  echo "❌ Sem internet"
  exit 1
}
echo "✅ Internet OK"

# ===============================
# INSTALAR SSH
# ===============================
echo "📦 Instalando SSH server..."

case "$DISTRO" in
  fedora|rhel|centos)
    dnf install -y openssh-server
    systemctl enable sshd
    systemctl start sshd
    ;;
  ubuntu|debian|linuxmint)
    apt update -y
    apt install -y openssh-server
    systemctl enable ssh
    systemctl start ssh
    ;;
  *)
    echo "❌ Distro não suportada"
    exit 1
    ;;
esac

# ===============================
# FIREWALL
# ===============================
echo "🔥 Configurando firewall..."

if systemctl is-active --quiet firewalld; then
  firewall-cmd --add-service=ssh --permanent
  firewall-cmd --reload
  echo "✅ Porta SSH liberada (firewalld)"
elif command -v ufw >/dev/null; then
  ufw allow ssh
  ufw reload || true
  echo "✅ Porta SSH liberada (ufw)"
else
  echo "⚠️ Nenhum firewall detectado"
fi

# ===============================
# TESTES
# ===============================
echo "🧪 Testando SSH..."
systemctl is-active ssh || systemctl is-active sshd

echo "🧪 Testando porta 22..."
ss -tln | grep ':22' && echo "✅ Porta 22 aberta" || echo "❌ Porta 22 fechada"

# ===============================
# IP FINAL
# ===============================
IP=$(hostname -I | awk '{print $1}')
echo
echo "🎉 SSH pronto!"
echo "➡️ Conecte-se com:"
echo "   ssh usuario@$IP"
