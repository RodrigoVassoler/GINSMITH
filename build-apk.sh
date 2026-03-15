#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Gin Aromatics Lab — APK Builder
#  Repositório: github.com/RodrigoVassoler/GINSMITH
#  App URL:     https://RodrigoVassoler.github.io/GINSMITH
#
#  Uso:  bash build-apk.sh
#
#  Este script instala automaticamente tudo que falta (Node.js, Java, Bubblewrap)
#  e gera gin-aromatics-lab.apk pronto para instalar no Android.
# ═══════════════════════════════════════════════════════════════════════════════
set -e

# ── Cores ──────────────────────────────────────────────────────────────────────
C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'
log()  { echo -e "${C}▶ $*${N}"; }
ok()   { echo -e "${G}✓ $*${N}"; }
warn() { echo -e "${Y}⚠ $*${N}"; }
err()  { echo -e "${R}✗ ERRO: $*${N}"; exit 1; }
title(){ echo -e "\n${B}$*${N}"; }

# ── Config ─────────────────────────────────────────────────────────────────────
APP_URL="https://RodrigoVassoler.github.io/GINSMITH"
PACKAGE_ID="com.ginsmith.aromatics"
APP_NAME="Gin Aromatics Lab"
LAUNCHER_NAME="Gin Lab"
VERSION_NAME="1.0.0"
VERSION_CODE=1
KEYSTORE="gin-lab-key.keystore"
KEY_ALIAS="gin-lab"
# ⚠️ Troque esta senha antes de distribuir o APK publicamente:
KEY_PASS="GinLab@2025"

echo ""
echo -e "${G}╔══════════════════════════════════════════╗${N}"
echo -e "${G}║   🌿  Gin Aromatics Lab — APK Builder    ║${N}"
echo -e "${G}╚══════════════════════════════════════════╝${N}"
echo ""
log "App: $APP_URL"
log "Package: $PACKAGE_ID"
echo ""

# ── Detectar distro Linux ──────────────────────────────────────────────────────
DISTRO=""
if [ -f /etc/os-release ]; then
  source /etc/os-release
  DISTRO="$ID"
fi
IS_DEBIAN=false
IS_FEDORA=false
IS_ARCH=false
case "$DISTRO" in
  ubuntu|debian|linuxmint|pop) IS_DEBIAN=true ;;
  fedora|rhel|centos)          IS_FEDORA=true ;;
  arch|manjaro)                IS_ARCH=true ;;
esac

# ── Instalar Node.js se necessário ────────────────────────────────────────────
title "1/4 — Verificando Node.js"
NODE_OK=false
if command -v node &>/dev/null; then
  NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_VER" -ge 14 ]; then
    ok "Node.js $(node -v) encontrado"
    NODE_OK=true
  else
    warn "Node.js $(node -v) muito antigo (precisa 14+) — atualizando..."
  fi
fi

if [ "$NODE_OK" = false ]; then
  log "Instalando Node.js 20 LTS..."
  if $IS_DEBIAN; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>/dev/null
    sudo apt-get install -y nodejs 2>/dev/null
  elif $IS_FEDORA; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - 2>/dev/null
    sudo dnf install -y nodejs 2>/dev/null
  elif $IS_ARCH; then
    sudo pacman -S --noconfirm nodejs npm 2>/dev/null
  else
    warn "Distro não reconhecida. Instale Node.js 14+ manualmente:"
    warn "  https://nodejs.org/en/download"
    err "Node.js 14+ necessário para continuar"
  fi
  ok "Node.js $(node -v) instalado"
fi

# ── Instalar Java se necessário ────────────────────────────────────────────────
title "2/4 — Verificando Java"
JAVA_OK=false
if command -v java &>/dev/null; then
  ok "Java encontrado: $(java -version 2>&1 | head -1)"
  JAVA_OK=true
fi

if [ "$JAVA_OK" = false ]; then
  log "Instalando Java 17 JDK..."
  if $IS_DEBIAN; then
    sudo apt-get update -qq 2>/dev/null
    sudo apt-get install -y default-jdk 2>/dev/null || \
    sudo apt-get install -y openjdk-17-jdk 2>/dev/null
  elif $IS_FEDORA; then
    sudo dnf install -y java-17-openjdk-devel 2>/dev/null
  elif $IS_ARCH; then
    sudo pacman -S --noconfirm jdk-openjdk 2>/dev/null
  else
    warn "Instale Java JDK 8+ manualmente: https://adoptium.net"
    err "Java necessário para assinar o APK"
  fi
  ok "Java instalado: $(java -version 2>&1 | head -1)"
fi

# ── Configurar JAVA_HOME se não estiver definido ───────────────────────────────
if [ -z "$JAVA_HOME" ]; then
  JAVA_BIN=$(which java)
  JAVA_REAL=$(readlink -f "$JAVA_BIN")
  export JAVA_HOME=$(dirname $(dirname "$JAVA_REAL"))
  log "JAVA_HOME configurado: $JAVA_HOME"
fi

# ── Instalar Bubblewrap CLI ────────────────────────────────────────────────────
title "3/4 — Verificando Bubblewrap CLI"
if command -v bubblewrap &>/dev/null; then
  ok "Bubblewrap $(bubblewrap --version 2>/dev/null || echo 'instalado')"
else
  log "Instalando Bubblewrap CLI (ferramenta oficial Google)..."
  npm install -g @bubblewrap/cli 2>&1 | tail -3
  # Garantir que npm global está no PATH
  NPM_BIN=$(npm bin -g 2>/dev/null || npm root -g | sed 's/node_modules/\.bin/')
  export PATH="$NPM_BIN:$PATH"
  ok "Bubblewrap instalado"
fi

# ── Build do APK ───────────────────────────────────────────────────────────────
title "4/4 — Gerando APK"

BUILD_DIR="./apk-build-$(date +%Y%m%d-%H%M)"
log "Diretório de build: $BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Keystore — reutiliza se já existir na pasta pai
if [ -f "../$KEYSTORE" ]; then
  log "Keystore existente encontrado — reutilizando"
  cp "../$KEYSTORE" "./$KEYSTORE"
  ok "Keystore: $KEYSTORE"
else
  log "Gerando keystore de assinatura..."
  keytool -genkeypair \
    -keystore "./$KEYSTORE" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$KEY_PASS" -keypass "$KEY_PASS" \
    -dname "CN=$APP_NAME, OU=Dev, O=GINSMITH, L=BR, ST=BR, C=BR" \
    2>/dev/null
  cp "./$KEYSTORE" "../$KEYSTORE"
  ok "Keystore criado e salvo em ../$KEYSTORE"
  echo ""
  echo -e "${Y}╔══════════════════════════════════════════════════╗${N}"
  echo -e "${Y}║  IMPORTANTE: guarde o arquivo $KEYSTORE  ║${N}"
  echo -e "${Y}║  Você precisará dele para assinar atualizações!  ║${N}"
  echo -e "${Y}╚══════════════════════════════════════════════════╝${N}"
  echo ""
fi

# Criar twa-manifest.json
log "Criando configuração TWA..."
cat > twa-manifest.json << TWAJSON
{
  "packageId": "$PACKAGE_ID",
  "host": "RodrigoVassoler.github.io",
  "name": "$APP_NAME",
  "launcherName": "$LAUNCHER_NAME",
  "display": "standalone",
  "orientation": "default",
  "themeColor": "#060c06",
  "navigationColor": "#060c06",
  "backgroundColor": "#060c06",
  "enableNotifications": false,
  "startUrl": "/GINSMITH/",
  "iconUrl": "https://raw.githubusercontent.com/RodrigoVassoler/GINSMITH/main/icons/icon-512.png",
  "maskableIconUrl": "https://raw.githubusercontent.com/RodrigoVassoler/GINSMITH/main/icons/icon-512.png",
  "appVersion": "$VERSION_NAME",
  "appVersionCode": $VERSION_CODE,
  "signingKey": {
    "path": "./$KEYSTORE",
    "alias": "$KEY_ALIAS"
  },
  "splashScreenFadeOutDuration": 300,
  "generatorApp": "bubblewrap-cli",
  "webManifestUrl": "https://raw.githubusercontent.com/RodrigoVassoler/GINSMITH/main/manifest.json",
  "fallbackType": "customtabs",
  "features": {},
  "alphaDependencies": { "enabled": false },
  "enableSiteSettingsShortcut": true,
  "isChromeOSOnly": false,
  "isMetaQuest": false,
  "fullScopeUrl": "https://RodrigoVassoler.github.io/GINSMITH/",
  "minSdkVersion": 19,
  "targetSdkVersion": 34
}
TWAJSON
ok "twa-manifest.json criado"

echo ""
log "Iniciando build..."
warn "Na primeira execução o Bubblewrap baixa o Android SDK (~500MB)"
warn "Pode demorar 5–15 minutos dependendo da sua conexão"
echo ""

# Aceitar licenças do Android SDK automaticamente se sdkmanager disponível
SDK_DIR="$HOME/.bubblewrap/android_sdk"
mkdir -p "$SDK_DIR/licenses" 2>/dev/null || true
echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$SDK_DIR/licenses/android-sdk-license" 2>/dev/null || true
echo -e "\nd56f5187479451eabf01fb78af6dfcb131a6481e" >> "$SDK_DIR/licenses/android-sdk-license" 2>/dev/null || true
echo -e "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$SDK_DIR/licenses/android-sdk-preview-license" 2>/dev/null || true

# Build com output filtrado para mostrar apenas linhas relevantes
bubblewrap build --skipPwaValidation 2>&1 | grep -E "BUILD|DOWNLOAD|Error|error|APK|apk|Signing|signing|SUCCESS|FAILED|%|\.apk" || true

# ── Localizar APK gerado ───────────────────────────────────────────────────────
echo ""
# Procura primeiro APK assinado, depois qualquer APK
APK_FILE=$(find . -name "app-release-signed.apk" 2>/dev/null | head -1)
[ -z "$APK_FILE" ] && APK_FILE=$(find . -name "*release*.apk" 2>/dev/null | head -1)
[ -z "$APK_FILE" ] && APK_FILE=$(find . -name "*.apk" 2>/dev/null | head -1)

cd ..

if [ -n "$APK_FILE" ]; then
  OUTPUT_APK="./gin-aromatics-lab.apk"
  cp "$BUILD_DIR/$APK_FILE" "$OUTPUT_APK"
  APK_SIZE=$(du -sh "$OUTPUT_APK" | cut -f1)

  echo ""
  echo -e "${G}╔══════════════════════════════════════════════════════╗${N}"
  echo -e "${G}║                                                      ║${N}"
  echo -e "${G}║   ✅  APK GERADO COM SUCESSO!                        ║${N}"
  echo -e "${G}║   📦  gin-aromatics-lab.apk  ($APK_SIZE)                  ║${N}"
  echo -e "${G}║                                                      ║${N}"
  echo -e "${G}╚══════════════════════════════════════════════════════╝${N}"
  echo ""
  echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo -e "${B}  Como instalar no celular Android:${N}"
  echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo ""
  echo "  Passo 1 — Transfira o APK para o celular:"
  echo "    • WhatsApp: envie para você mesmo em chat pessoal"
  echo "    • Google Drive: faça upload e baixe no celular"
  echo "    • Cabo USB: copie para qualquer pasta"
  echo ""
  echo "  Passo 2 — Abra gin-aromatics-lab.apk no celular"
  echo ""
  echo "  Passo 3 — Se aparecer 'Bloqueado por segurança':"
  echo "    Android 8+: Configurações → Apps → ⚙ Acesso especial"
  echo "               → Instalar apps desconhecidos"
  echo "               → Gerenciador de arquivos → Permitir"
  echo "    Android 7: Configurações → Segurança"
  echo "               → Fontes desconhecidas → Ativar"
  echo ""
  echo "  Passo 4 — Toque INSTALAR → aguarde ~10 segundos"
  echo "    O ícone 🌿 aparecerá na sua tela inicial!"
  echo ""
  echo -e "${Y}  ⚠  Guarde o arquivo: $KEYSTORE${N}"
  echo -e "${Y}     Necessário para assinar versões futuras do APK${N}"
  echo ""
else
  echo ""
  warn "APK não encontrado. Conteúdo do diretório de build:"
  find "$BUILD_DIR" -name "*.apk" 2>/dev/null || echo "  (nenhum .apk encontrado)"
  echo ""
  echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo -e "${B}  Alternativa: PWABuilder (zero instalação)${N}"
  echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo ""
  echo "  1. Acesse https://www.pwabuilder.com"
  echo "  2. Cole a URL: https://RodrigoVassoler.github.io/GINSMITH"
  echo "  3. Clique Start → Android → Generate Package"
  echo "  4. Baixe o APK e transfira para o celular"
  echo ""
fi
