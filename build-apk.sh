#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Gin Aromatics Lab — APK Builder
#  Repositório: github.com/RodrigoVassoler/GINSMITH
#
#  Uso:
#    bash build-apk.sh
#
#  O script verifica dependências, gera o APK via Bubblewrap CLI e
#  produz gin-aromatics-lab.apk pronto para instalar no Android.
#
#  Requisitos:
#    - Node.js 14+   → https://nodejs.org
#    - Java JDK 8+   → https://adoptium.net
#    - Conexão com internet (para baixar Bubblewrap + Android SDK)
# ═══════════════════════════════════════════════════════════════════════════════

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${CYAN}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
err()  { echo -e "${RED}✗ $1${NC}"; exit 1; }

# ── Configuração do app ────────────────────────────────────────────────────────
APP_URL="https://RodrigoVassoler.github.io/GINSMITH"
PACKAGE_ID="com.ginsmith.aromatics"
APP_NAME="Gin Aromatics Lab"
LAUNCHER_NAME="Gin Lab"
VERSION_NAME="1.0.0"
VERSION_CODE=1
KEYSTORE="gin-lab-key.keystore"
KEY_ALIAS="gin-lab"
KEY_PASS="ginlab@2025"      # ← Troque antes de distribuir publicamente

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🌿 Gin Aromatics Lab — APK Builder  ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""
log "URL do app: $APP_URL"
echo ""

# ── Verificar Node.js ──────────────────────────────────────────────────────────
log "Verificando Node.js..."
if ! command -v node &>/dev/null; then
  err "Node.js não encontrado. Instale em: https://nodejs.org"
fi
NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VER" -lt 14 ]; then
  err "Node.js 14+ necessário (atual: $(node -v)). Atualize em https://nodejs.org"
fi
ok "Node.js $(node -v)"

# ── Verificar Java ─────────────────────────────────────────────────────────────
log "Verificando Java..."
if ! command -v java &>/dev/null; then
  err "Java não encontrado. Instale o JDK 8+ em: https://adoptium.net"
fi
ok "Java $(java -version 2>&1 | head -1 | awk -F'"' '{print $2}')"

# ── Instalar Bubblewrap CLI ────────────────────────────────────────────────────
log "Verificando Bubblewrap CLI..."
if ! command -v bubblewrap &>/dev/null; then
  warn "Bubblewrap não encontrado — instalando..."
  npm install -g @bubblewrap/cli
  ok "Bubblewrap instalado"
else
  ok "Bubblewrap $(bubblewrap --version 2>/dev/null || echo 'OK')"
fi

# ── Criar diretório de build ───────────────────────────────────────────────────
BUILD_DIR="./apk-build-$(date +%Y%m%d-%H%M%S)"
log "Criando diretório de build: $BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# ── Gerar ou copiar keystore ───────────────────────────────────────────────────
PARENT_KEYSTORE="../$KEYSTORE"
if [ -f "$PARENT_KEYSTORE" ]; then
  log "Keystore existente encontrado — reutilizando..."
  cp "$PARENT_KEYSTORE" "./$KEYSTORE"
  ok "Keystore copiado: $KEYSTORE"
else
  log "Gerando keystore de assinatura..."
  keytool -genkeypair \
    -keystore "./$KEYSTORE" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$KEY_PASS" -keypass "$KEY_PASS" \
    -dname "CN=$APP_NAME, OU=Dev, O=GINSMITH, L=BR, ST=BR, C=BR" \
    2>/dev/null
  cp "./$KEYSTORE" "$PARENT_KEYSTORE"
  ok "Keystore gerado e salvo em ../$KEYSTORE"
  echo ""
  warn "IMPORTANTE: Guarde o arquivo $KEYSTORE com segurança!"
  warn "Você precisará dele para publicar atualizações do APK."
  echo ""
fi

# ── Criar twa-manifest.json ────────────────────────────────────────────────────
log "Criando manifesto TWA..."
HOST=$(echo "$APP_URL" | sed 's|https://||' | cut -d/ -f1)
START_PATH="/"$(echo "$APP_URL" | sed 's|https://[^/]*||')

cat > twa-manifest.json << EOF
{
  "packageId": "$PACKAGE_ID",
  "host": "$HOST",
  "name": "$APP_NAME",
  "launcherName": "$LAUNCHER_NAME",
  "display": "standalone",
  "orientation": "default",
  "themeColor": "#060c06",
  "navigationColor": "#060c06",
  "backgroundColor": "#060c06",
  "enableNotifications": false,
  "startUrl": "/GINSMITH/",
  "iconUrl": "$APP_URL/icons/icon-512.png",
  "maskableIconUrl": "$APP_URL/icons/icon-512.png",
  "appVersion": "$VERSION_NAME",
  "appVersionCode": $VERSION_CODE,
  "signingKey": {
    "path": "./$KEYSTORE",
    "alias": "$KEY_ALIAS"
  },
  "splashScreenFadeOutDuration": 300,
  "generatorApp": "bubblewrap-cli",
  "webManifestUrl": "$APP_URL/manifest.json",
  "fallbackType": "customtabs",
  "features": {},
  "alphaDependencies": { "enabled": false },
  "enableSiteSettingsShortcut": true,
  "isChromeOSOnly": false,
  "isMetaQuest": false,
  "fullScopeUrl": "$APP_URL/",
  "minSdkVersion": 19,
  "targetSdkVersion": 34
}
EOF
ok "twa-manifest.json criado"

# ── Build ──────────────────────────────────────────────────────────────────────
echo ""
log "Iniciando build do APK (pode demorar 5-15 min na primeira vez)..."
log "O Bubblewrap vai baixar o Android SDK automaticamente se necessário."
echo ""

bubblewrap build --skipPwaValidation 2>&1 | while IFS= read -r line; do
  echo "  $line"
done

# ── Localizar APK ─────────────────────────────────────────────────────────────
echo ""
APK_FILE=$(find . -name "*.apk" 2>/dev/null | grep -v "unsigned" | head -1)
if [ -z "$APK_FILE" ]; then
  APK_FILE=$(find . -name "*.apk" 2>/dev/null | head -1)
fi

if [ -n "$APK_FILE" ]; then
  OUTPUT="../gin-aromatics-lab.apk"
  cp "$APK_FILE" "$OUTPUT"
  APK_SIZE=$(du -sh "$OUTPUT" | cut -f1)
  cd ..
  echo ""
  echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✅  APK GERADO COM SUCESSO!                 ║${NC}"
  echo -e "${GREEN}╠═══════════════════════════════════════════════╣${NC}"
  echo -e "${GREEN}║   📦 gin-aromatics-lab.apk ($APK_SIZE)              ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}Como instalar no celular:${NC}"
  echo "  1. Transfira o APK para o Android (WhatsApp, Drive, cabo USB)"
  echo "  2. Abra o arquivo no celular"
  echo "  3. Se aparecer aviso de segurança:"
  echo "     Configurações → Segurança → Instalar apps desconhecidos → Permitir"
  echo "  4. Toque em Instalar"
  echo ""
  echo -e "${CYAN}Keystore (guarde com segurança!):${NC}"
  echo "  📁 $KEYSTORE — necessário para assinar futuras atualizações"
  echo ""
else
  cd ..
  echo ""
  warn "APK não encontrado no diretório de build."
  echo ""
  echo "Alternativa sem linha de comando (método mais simples):"
  echo "  1. Acesse https://www.pwabuilder.com"
  echo "  2. Cole a URL: $APP_URL"
  echo "  3. Clique Start → Android → Generate Package"
  echo "  4. Baixe o APK gerado"
fi
