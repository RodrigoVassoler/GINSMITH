#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  Gin Aromatics Lab — Gerador de APK Android
#  Usa Bubblewrap CLI (ferramenta oficial Google para PWA → APK)
# ═══════════════════════════════════════════════════════════════════
set -e

# ── Configuração ──────────────────────────────────────────────────
APP_URL="${1:-https://SEU_USUARIO.github.io/gin-lab}"
PACKAGE_ID="com.ginlab.aromatics"
APP_NAME="Gin Aromatics Lab"
APP_VERSION="1.0.0"
APP_VERSION_CODE="1"

echo ""
echo "🌿 Gin Aromatics Lab — APK Builder"
echo "════════════════════════════════════"
echo "URL: $APP_URL"
echo ""

# ── Verificar dependências ────────────────────────────────────────
check_dep() {
  if ! command -v "$1" &> /dev/null; then
    echo "❌ '$1' não encontrado. $2"
    exit 1
  fi
}

check_dep node "Instale Node.js em https://nodejs.org"
check_dep java "Instale Java JDK 8+ em https://adoptium.net"

NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VER" -lt 14 ]; then
  echo "❌ Node.js 14+ necessário (atual: $(node -v))"
  exit 1
fi

echo "✓ Node.js $(node -v)"
echo "✓ Java $(java -version 2>&1 | head -1)"
echo ""

# ── Instalar Bubblewrap se necessário ─────────────────────────────
if ! command -v bubblewrap &> /dev/null; then
  echo "📦 Instalando Bubblewrap CLI..."
  npm install -g @bubblewrap/cli
  echo "✓ Bubblewrap instalado"
else
  echo "✓ Bubblewrap $(bubblewrap --version 2>/dev/null || echo 'instalado')"
fi

echo ""

# ── Criar diretório de build ──────────────────────────────────────
BUILD_DIR="./apk-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# ── Inicializar projeto TWA ────────────────────────────────────────
echo "🔧 Inicializando projeto TWA..."
echo ""

# Criar twa-manifest.json manualmente para evitar prompts interativos
cat > twa-manifest.json << EOF
{
  "packageId": "$PACKAGE_ID",
  "host": "$(echo $APP_URL | sed 's|https://||' | cut -d/ -f1)",
  "name": "$APP_NAME",
  "launcherName": "Gin Lab",
  "display": "standalone",
  "orientation": "default",
  "themeColor": "#060c06",
  "navigationColor": "#060c06",
  "backgroundColor": "#060c06",
  "enableNotifications": false,
  "startUrl": "/",
  "iconUrl": "$APP_URL/icons/icon-512.png",
  "maskableIconUrl": "$APP_URL/icons/icon-512.png",
  "appVersion": "$APP_VERSION",
  "appVersionCode": $APP_VERSION_CODE,
  "signingKey": {
    "path": "./gin-lab-key.keystore",
    "alias": "gin-lab"
  },
  "splashScreenFadeOutDuration": 300,
  "generatorApp": "bubblewrap-cli",
  "webManifestUrl": "$APP_URL/manifest.json",
  "fallbackType": "customtabs",
  "features": {},
  "alphaDependencies": {
    "enabled": false
  },
  "enableSiteSettingsShortcut": true,
  "isChromeOSOnly": false,
  "isMetaQuest": false,
  "fullScopeUrl": "$APP_URL/",
  "minSdkVersion": 19,
  "targetSdkVersion": 34
}
EOF

echo "✓ twa-manifest.json criado"

# ── Gerar keystore para assinar o APK ─────────────────────────────
echo ""
echo "🔑 Gerando keystore de assinatura..."
keytool -genkeypair \
  -keystore gin-lab-key.keystore \
  -alias gin-lab \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass ginlab123 \
  -keypass ginlab123 \
  -dname "CN=Gin Lab, OU=Dev, O=GinLab, L=BR, ST=BR, C=BR" \
  2>/dev/null
echo "✓ Keystore gerado: gin-lab-key.keystore"
echo "  ⚠️  Guarde este arquivo — necessário para atualizações futuras"

# ── Build do APK ──────────────────────────────────────────────────
echo ""
echo "🏗️  Construindo APK..."
bubblewrap build --skipPwaValidation 2>&1 | tail -20

# ── Localizar APK gerado ──────────────────────────────────────────
APK_PATH=$(find . -name "*.apk" | head -1)

if [ -n "$APK_PATH" ]; then
  cp "$APK_PATH" "../gin-aromatics-lab.apk"
  APK_SIZE=$(du -sh "../gin-aromatics-lab.apk" | cut -f1)
  echo ""
  echo "══════════════════════════════════════════"
  echo "✅ APK GERADO COM SUCESSO!"
  echo "   Arquivo: gin-aromatics-lab.apk ($APK_SIZE)"
  echo "══════════════════════════════════════════"
  echo ""
  echo "📱 Para instalar:"
  echo "   1. Copie gin-aromatics-lab.apk para o Android"
  echo "   2. Abra o arquivo no celular"
  echo "   3. Se necessário: Configurações → Segurança → Instalar apps desconhecidos"
  echo ""
  echo "🔑 IMPORTANTE: Guarde o arquivo gin-lab-key.keystore"
  echo "   Você precisará dele para publicar atualizações"
else
  echo ""
  echo "⚠️  APK não encontrado no diretório de build."
  echo "    Use o método alternativo: https://www.pwabuilder.com"
  echo "    Cole a URL: $APP_URL"
fi

cd ..
