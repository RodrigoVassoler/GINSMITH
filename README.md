# 🌿 Gin Aromatics Lab — GINSMITH

**Modelagem físico-química de perfis aromáticos para gin e coquetéis.**  
PWA instalável · Funciona offline · Atualizações automáticas via GitHub.

🔗 **App:** https://RodrigoVassoler.github.io/GINSMITH  
📲 **Instalar:** https://RodrigoVassoler.github.io/GINSMITH/install.html  
📦 **Repositório:** https://github.com/RodrigoVassoler/GINSMITH

---

## 📁 Estrutura do repositório

```
GINSMITH/
├── index.html              ← App completo (React + lógica, sem build step)
├── install.html            ← Landing page de instalação com QR Code
├── manifest.json           ← Configuração PWA
├── sw.js                   ← Service Worker (cache offline)
├── botanicals.json         ← Banco remoto de ingredientes (editável)
├── recipes.json            ← Sync de receitas entre dispositivos
├── build-apk.sh            ← Gerador de APK Android
├── build_html.py           ← Gerador de index.html a partir do JSX
├── aroma_neural_net.jsx    ← Código-fonte React (referência)
├── icons/                  ← Ícones PWA (72px → 512px)
└── .github/
    └── workflows/
        └── deploy.yml      ← Deploy automático no push para main
```

---

## 🚀 Como o deploy funciona

Toda vez que você faz `git push` para `main`, o GitHub Actions publica automaticamente o app em:  
**https://RodrigoVassoler.github.io/GINSMITH**

Não há build step. O `index.html` já contém todo o app — React carrega via CDN e o Babel transpila o JSX diretamente no navegador.

### Configurar GitHub Pages (primeira vez)

1. Repositório → **Settings → Pages**
2. Source: **"GitHub Actions"**
3. Salvar

---

## 🔄 Atualizar ingredientes

Edite `botanicals.json`, incremente a versão e faça push:

```json
{
  "version": "1.1.0",
  "releaseNotes": "3 novos botânicos amazônicos",
  "updatedAt": "2025-06-15",
  "botanicals": {
    "Cumaru": {
      "icon": "🌳",
      "category": "Amadeirados",
      "compounds": [
        { "name": "Cumarina", "conc": 3.5, "aroma": "Adocicado", "min": 0.001, "max": 0.02 }
      ]
    }
  }
}
```

Na próxima abertura do app com internet, aparece o **banner azul de atualização**. O usuário clica "⬇ Atualizar" e os novos botânicos são mesclados sem apagar o estoque existente.

---

## 💾 Sincronizar receitas entre dispositivos

1. No app: **📚 → ⬇ Exportar** → baixa `gin-lab-receitas-YYYY-MM-DD.json`
2. Renomeie para `recipes.json`
3. Commite no repositório: `git add recipes.json && git commit -m "sync recipes" && git push`
4. Em outro dispositivo: o app busca automaticamente em `botanicals.json` → `recipes.json` do mesmo repositório

---

## 📱 Gerar APK Android

### Método 1 — Script automático (linha de comando)

**Requisitos:**
- Node.js 14+ → https://nodejs.org
- Java JDK 8+ → https://adoptium.net

```bash
# Clone o repositório
git clone https://github.com/RodrigoVassoler/GINSMITH.git
cd GINSMITH

# Rode o script
bash build-apk.sh
```

O script:
1. Verifica Node.js e Java
2. Instala o Bubblewrap CLI (ferramenta oficial Google para PWA → APK)
3. Gera um keystore de assinatura (guarde o arquivo `.keystore`!)
4. Faz o build do APK via Trusted Web Activity (TWA)
5. Salva `gin-aromatics-lab.apk` na pasta raiz

**Primeira execução:** demora 5-15 min (Bubblewrap baixa o Android SDK ~500MB).  
**Execuções seguintes:** ~2 min (SDK já em cache).

### Método 2 — PWABuilder (zero instalação, mais simples)

1. Acesse https://www.pwabuilder.com
2. Cole: `https://RodrigoVassoler.github.io/GINSMITH`
3. Clique **Start** → **Android** → **Generate Package**
4. Baixe o `.apk`

---

## 📲 Instalar o APK no celular Android

### Passo a passo completo

**1. Transfira o APK para o celular**

Escolha uma das opções:
- **WhatsApp:** envie o `.apk` para si mesmo em uma conversa pessoal
- **Google Drive:** faça upload e baixe no celular
- **Cabo USB:** copie para qualquer pasta no celular
- **Bluetooth:** envie diretamente

**2. Abra o arquivo no celular**

No gerenciador de arquivos, localize e toque no `gin-aromatics-lab.apk`.

**3. Permitir instalação de apps desconhecidos**

Na primeira vez, o Android vai bloquear e mostrar um aviso. O caminho varia por versão:

| Android | Caminho |
|---|---|
| Android 8+ | Configurações → Apps → ícone de engrenagem → Acesso especial → Instalar apps desconhecidos → Gerenciador de arquivos → Permitir |
| Android 7 e abaixo | Configurações → Segurança → Fontes desconhecidas → Ativar |

**4. Instalar**

Toque **Instalar** → aguarde ~10 segundos → **Abrir** ou procure o ícone 🌿 na tela inicial.

### Atualizar o APK

Para instalar uma versão nova basta rodar `bash build-apk.sh` novamente (use o mesmo `.keystore`) e transferir o novo APK. O Android substitui automaticamente o anterior.

---

## 🔐 Painel Admin

Botão **🔬 Admin** no header do app.

**Senha padrão:** `ginlab2025`

Para alterar: edite `const ADMIN_PASSWORD` em `aroma_neural_net.jsx` e rode `python3 build_html.py` para regenerar o `index.html`.

**Funcionalidades:**
- 📋 Visualizar e editar todos os 70+ botânicos
- ✏️ Alterar ícone, categoria, compostos, concentrações
- ⬇ Exportar banco como JSON (backup / atualização)
- 📥 Importar JSON (mesclar ou substituir)
- 🔄 Buscar atualização de qualquer URL pública

---

## 🔧 Personalização

| O que mudar | Onde | Como aplicar |
|---|---|---|
| Senha admin | `ADMIN_PASSWORD` em `aroma_neural_net.jsx` | `python3 build_html.py` |
| Versão do banco | `DB_VERSION` em `aroma_neural_net.jsx` | `python3 build_html.py` |
| Novos ingredientes | `botanicals.json` | `git push` |
| Nome/tema do app | `manifest.json` + `<title>` em `index.html` | editar direto |

---

## 🛠 Rodar localmente (sem Vite, sem build)

Este projeto **não usa Vite nem qualquer build step**. Para testar localmente:

```bash
# Python (já vem no Linux/Mac)
python3 -m http.server 8080
# Acesse http://localhost:8080

# Node.js
npx serve .
# Acesse http://localhost:3000
```

> ⚠️ Não abra o `index.html` diretamente com `file://` — o Service Worker não funciona assim.  
> Sempre use um servidor HTTP local.

---

## 📊 Tech stack

| Componente | Tecnologia |
|---|---|
| UI | React 18 via CDN |
| Transpilação | Babel Standalone (no browser) |
| PDF | jsPDF 2.5 via CDN |
| Offline | Service Worker (Cache-First) |
| Persistência | localStorage |
| Deploy | GitHub Pages + Actions |
| APK Android | Bubblewrap CLI (TWA) |

---

*Gin Aromatics Lab — modelagem de perfis aromáticos baseada em limiares de percepção e fatores de extração*  
*Repositório: github.com/RodrigoVassoler/GINSMITH*
