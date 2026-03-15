#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  Gin Aromatics Lab — Instalador de Dependências
#  Instala Node.js 20 LTS + Java JDK 17 no Linux (Ubuntu/Debian/Fedora/Arch)
#
#  Uso: bash instalar-dependencias.sh
# ═══════════════════════════════════════════════════════════════════
set -e
G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; N='\033[0m'; B='\033[1m'
ok()  { echo -e "${G}✓ $*${N}"; }
log() { echo -e "${C}▶ $*${N}"; }
warn(){ echo -e "${Y}⚠ $*${N}"; }

echo ""
echo -e "${B}🌿 Gin Aromatics Lab — Instalador de Dependências${N}"
echo ""

# Detectar distro
source /etc/os-release 2>/dev/null || true
DISTRO="${ID:-unknown}"
log "Sistema: $PRETTY_NAME ($DISTRO)"
echo ""

# ── Node.js ────────────────────────────────────────────────────────
log "Verificando Node.js..."
NEED_NODE=true
if command -v node &>/dev/null; then
  VER=$(node -v | sed 's/v//' | cut -d. -f1)
  if [ "$VER" -ge 14 ]; then
    ok "Node.js $(node -v) já instalado"
    NEED_NODE=false
  else
    warn "Node.js $(node -v) desatualizado — atualizando para v20 LTS"
  fi
fi

if $NEED_NODE; then
  log "Instalando Node.js 20 LTS..."
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop|elementary)
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      sudo apt-get install -y nodejs
      ;;
    fedora)
      curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
      sudo dnf install -y nodejs
      ;;
    centos|rhel)
      curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
      sudo yum install -y nodejs
      ;;
    arch|manjaro|endeavouros)
      sudo pacman -S --noconfirm nodejs npm
      ;;
    opensuse*|sles)
      sudo zypper install -y nodejs20
      ;;
    *)
      warn "Distro '$DISTRO' não reconhecida automaticamente."
      warn "Instale Node.js 14+ manualmente: https://nodejs.org/en/download"
      warn "Ou use o NVM: https://github.com/nvm-sh/nvm"
      ;;
  esac
  [ -n "$(command -v node)" ] && ok "Node.js $(node -v) instalado com sucesso"
fi

# ── Java JDK ───────────────────────────────────────────────────────
echo ""
log "Verificando Java JDK..."
NEED_JAVA=true
if command -v java &>/dev/null; then
  ok "Java já instalado: $(java -version 2>&1 | head -1)"
  NEED_JAVA=false
fi

if $NEED_JAVA; then
  log "Instalando Java JDK 17..."
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop|elementary)
      sudo apt-get update -qq
      sudo apt-get install -y default-jdk 2>/dev/null \
        || sudo apt-get install -y openjdk-17-jdk
      ;;
    fedora)
      sudo dnf install -y java-17-openjdk-devel
      ;;
    centos|rhel)
      sudo yum install -y java-17-openjdk-devel
      ;;
    arch|manjaro|endeavouros)
      sudo pacman -S --noconfirm jdk-openjdk
      ;;
    opensuse*|sles)
      sudo zypper install -y java-17-openjdk-devel
      ;;
    *)
      warn "Instale Java JDK 8+ manualmente: https://adoptium.net"
      ;;
  esac
  command -v java &>/dev/null && ok "Java instalado: $(java -version 2>&1 | head -1)"
fi

# ── Configurar JAVA_HOME ───────────────────────────────────────────
echo ""
log "Configurando JAVA_HOME..."
if [ -z "$JAVA_HOME" ]; then
  JAVA_REAL=$(readlink -f "$(which java)" 2>/dev/null || true)
  if [ -n "$JAVA_REAL" ]; then
    JAVA_HOME_VAL=$(dirname "$(dirname "$JAVA_REAL")")
    # Adicionar ao .bashrc e .profile
    for RC in "$HOME/.bashrc" "$HOME/.profile"; do
      if ! grep -q "JAVA_HOME" "$RC" 2>/dev/null; then
        echo "" >> "$RC"
        echo "# Java" >> "$RC"
        echo "export JAVA_HOME=\"$JAVA_HOME_VAL\"" >> "$RC"
        echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> "$RC"
      fi
    done
    export JAVA_HOME="$JAVA_HOME_VAL"
    ok "JAVA_HOME=$JAVA_HOME"
  fi
else
  ok "JAVA_HOME já definido: $JAVA_HOME"
fi

# ── npm global path ────────────────────────────────────────────────
echo ""
log "Configurando PATH para npm global..."
NPM_PREFIX=$(npm config get prefix 2>/dev/null || echo "$HOME/.npm-global")
NPM_BIN="$NPM_PREFIX/bin"
if [[ ":$PATH:" != *":$NPM_BIN:"* ]]; then
  for RC in "$HOME/.bashrc" "$HOME/.profile"; do
    if ! grep -q "$NPM_BIN" "$RC" 2>/dev/null; then
      echo "export PATH=\"$NPM_BIN:\$PATH\"" >> "$RC"
    fi
  done
  export PATH="$NPM_BIN:$PATH"
fi
ok "npm global bin: $NPM_BIN"

# ── Resumo ─────────────────────────────────────────────────────────
echo ""
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo -e "${G}  ✅  Dependências instaladas!${N}"
echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
echo ""
command -v node  &>/dev/null && echo "  • Node.js: $(node -v)"
command -v npm   &>/dev/null && echo "  • npm:     $(npm -v)"
command -v java  &>/dev/null && echo "  • Java:    $(java -version 2>&1 | awk -F'"' '/version/ {print $2}')"
echo "  • JAVA_HOME: ${JAVA_HOME:-'(reabra o terminal para aplicar)'}"
echo ""
echo -e "${Y}  Reabra o terminal e rode:${N}"
echo "    bash build-apk.sh"
echo ""
