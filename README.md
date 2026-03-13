# 🌿 Gin Aromatics Lab

App PWA para modelagem físico-química de perfis aromáticos em gin e coquetéis.  
**Funciona offline · instalável no Android, Windows e Linux · atualizações automáticas via GitHub.**

---

## 🚀 Setup em 5 minutos — GitHub Pages + Deploy Automático

### 1. Criar repositório

```bash
# No GitHub, crie um repositório público chamado: gin-lab
# (ou qualquer nome — ajuste a URL depois)
```

### 2. Configurar GitHub Pages

1. No repositório → **Settings → Pages**
2. Source: **"GitHub Actions"**
3. Salvar

### 3. Fazer o primeiro push

```bash
git init
git add .
git commit -m "feat: gin aromatics lab v1.0.0"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/gin-lab.git
git push -u origin main
```

Em ~1 minuto, o app estará em:  
`https://SEU_USUARIO.github.io/gin-lab`

### 4. Ativar atualizações automáticas no app

Abra `index.html` e localize:
```javascript
const GITHUB_RAW_URL = "";
```

Substitua por:
```javascript
const GITHUB_RAW_URL = "https://raw.githubusercontent.com/SEU_USUARIO/gin-lab/main/botanicals.json";
```

Faça o push. Pronto — o app vai verificar o JSON a cada abertura.

---

## 🔄 Workflow de atualização de ingredientes

### Adicionar novos botânicos remotamente

1. Edite o arquivo `botanicals.json`
2. Incremente a versão: `"version": "1.1.0"`
3. Adicione os novos botânicos no objeto `"botanicals"`
4. Faça commit e push para `main`

```json
{
  "version": "1.1.0",
  "releaseNotes": "5 novos botânicos da Amazônia",
  "updatedAt": "2025-06-01",
  "botanicals": {
    "Pimenta Baniwa": {
      "icon": "🌶",
      "category": "Especiarias",
      "compounds": [
        { "name": "Capsaicina", "conc": 0.5, "aroma": "Picante", "min": 0.01, "max": 0.10 }
      ]
    },
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

5. Na próxima vez que o usuário abrir o app com internet, aparece o **banner azul** de atualização
6. Ele clica **"⬇ Atualizar"** — novos ingredientes são mesclados sem apagar o estoque

> ℹ️ O `botanicals.json` só adiciona novos botânicos.  
> Botânicos da base original (no código) nunca são removidos.

### Alterar botânicos existentes

Use o **🔬 Painel Admin** dentro do app (requer senha `ginlab2025`):
- Aba **📋 Banco** → clique ✏️ para editar qualquer ingrediente
- Aba **📥 Importar JSON** → cole um JSON para importação em massa
- Aba **🔄 Atualizar via URL** → busca um JSON de qualquer URL

---

## 📱 Gerar APK para Android

### Método 1 — PWABuilder (zero instalação, recomendado)

1. Faça o deploy no GitHub Pages primeiro
2. Acesse **https://www.pwabuilder.com**
3. Cole a URL: `https://SEU_USUARIO.github.io/gin-lab`
4. Clique **"Start"** → aguarde a análise
5. Clique **"Android"** → **"Generate Package"**
6. Baixe o `.apk` e instale no celular (ative "Fontes desconhecidas" nas configurações)

> O APK gerado é uma **Trusted Web Activity (TWA)** — tecnologia oficial do Google  
> que empacota o PWA em um APK nativo sem overhead.

### Método 2 — Bubblewrap CLI (linha de comando)

Instale uma vez:
```bash
npm install -g @bubblewrap/cli
```

Na pasta do projeto:
```bash
bubblewrap init --manifest https://SEU_USUARIO.github.io/gin-lab/manifest.json
```

Responda as perguntas (ou aceite os padrões) e depois:
```bash
bubblewrap build
```

Gera `app-release-signed.apk` pronto para instalar.

**Requisitos:**
- Node.js 14+
- Java JDK 8+ (para assinar o APK)

### Instalar o APK no celular

1. Transfira o `.apk` para o Android (WhatsApp, cabo USB, Google Drive)
2. Abra o arquivo no celular
3. Se aparecer "Bloqueado por segurança": Configurações → Apps → Instalar apps desconhecidos → permitir para o gerenciador de arquivos
4. Instalar → Concluído

> **Sem Google Play Store** — instalação direta (sideload)

---

## 🔐 Painel Admin

Acesse pelo botão **🔬 Admin** no header do app.

**Senha padrão:** `ginlab2025`

Para alterar, edite em `index.html`:
```javascript
const ADMIN_PASSWORD = "sua_nova_senha";
```

**Funcionalidades:**
- 📋 Visualizar e editar todos os 70+ botânicos
- ✏️ Alterar ícone, categoria, compostos e concentrações
- ⬇ Exportar banco completo como JSON (para backup ou atualização)
- 📥 Importar JSON (mesclar ou substituir)
- 🔄 Buscar atualização de qualquer URL pública

---

## 📁 Estrutura do repositório

```
gin-lab/
├── index.html          ← App completo (React + toda a lógica)
├── manifest.json       ← Configuração PWA
├── sw.js               ← Service Worker (cache offline)
├── botanicals.json     ← Banco remoto de ingredientes (editável)
├── icons/              ← Ícones PWA (72px → 512px)
│   └── icon-*.png
└── .github/
    └── workflows/
        └── deploy.yml  ← GitHub Actions: push → deploy automático
```

---

## 🔧 Personalização

| O que mudar | Onde |
|---|---|
| Senha admin | `const ADMIN_PASSWORD` em `index.html` |
| URL do banco remoto | `const GITHUB_RAW_URL` em `index.html` |
| Versão do banco | `const DB_VERSION` em `index.html` |
| Nome do app | `"name"` em `manifest.json` e `<title>` em `index.html` |
| Cor do tema | `"theme_color"` em `manifest.json` |
| Novos ingredientes | Edite `botanicals.json` e incremente a versão |

---

## 📊 Tech stack

- **React 18** via CDN (sem build step)
- **Babel Standalone** para transpilação JSX no browser
- **Service Worker** com estratégia Cache-First para offline
- **localStorage** para persistência de estoque e configurações
- **GitHub Pages + Actions** para deploy automático
- **TWA / Bubblewrap** para empacotamento Android

---

*Gin Aromatics Lab — modelagem de perfis aromáticos baseada em limiares de percepção e fatores de extração*
