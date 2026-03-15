# 📱 Guia Completo: Build APK e Instalação Android

**App:** https://RodrigoVassoler.github.io/GINSMITH  
**Repositório:** https://github.com/RodrigoVassoler/GINSMITH

---

## ⚡ Método mais rápido (sem instalar nada)

**Use o PWABuilder — leva 2 minutos:**

1. Acesse **https://www.pwabuilder.com**
2. Cole a URL: `https://RodrigoVassoler.github.io/GINSMITH
3. Clique **Start**
4. Clique **Android** → **Generate Package**
5. Baixe o `.apk`
6. Transfira para o celular e instale (ver Passo 3 abaixo)

---

## 🛠 Método via linha de comando (build-apk.sh)

### Pré-requisitos

Você precisa de:
- **Node.js 14+** → https://nodejs.org
- **Java JDK 8+** → https://adoptium.net

**Verificar se já tem:**
```bash
node -v    # precisa mostrar v14+ (ex: v20.11.0)
java -version   # precisa mostrar qualquer versão
```

**Se não tiver, instale com o script incluso:**
```bash
bash instalar-dependencias.sh
# Feche e reabra o terminal depois
```

---

### Executar o build

```bash
# Na pasta do repositório GINSMITH:
bash build-apk.sh
```

**O que acontece internamente:**
1. Verifica Node.js e Java (instala se faltar)
2. Instala o **Bubblewrap CLI** (ferramenta oficial do Google para converter PWA em APK)
3. Gera um **keystore** de assinatura (`gin-lab-key.keystore`) — guarde este arquivo!
4. Baixa o **Android SDK** (~500MB — só na primeira vez, demora 5–15min)
5. Faz o build do APK via **Trusted Web Activity (TWA)**
6. Salva `gin-aromatics-lab.apk` na pasta raiz

**Execuções seguintes levam ~2 minutos** (SDK já em cache).

---

### Se o build falhar

O script detecta o erro e mostra o fallback do PWABuilder automaticamente.

Problemas comuns:

| Erro | Solução |
|---|---|
| `node: command not found` | `bash instalar-dependencias.sh` |
| `java: command not found` | `bash instalar-dependencias.sh` |
| `bubblewrap: command not found` | `npm install -g @bubblewrap/cli` |
| `SDK license not accepted` | O script aceita automaticamente — rode de novo |
| Timeout no download do SDK | Verifique a conexão e rode novamente |

---

## 📲 Instalar o APK no celular Android

### Passo 1 — Transfira o APK

Escolha a forma mais conveniente:

**WhatsApp (mais fácil):**
1. Abra o WhatsApp no computador
2. Abra uma conversa consigo mesmo (ícone de pessoa) ou "Mensagens para mim"
3. Clique no clipe 📎 → Documento
4. Selecione `gin-aromatics-lab.apk`
5. No celular, abra o WhatsApp e baixe o arquivo

**Google Drive:**
1. Acesse drive.google.com
2. Arraste o `gin-aromatics-lab.apk` para o Drive
3. No celular, abra o Drive e baixe o arquivo

**Cabo USB:**
1. Conecte o cabo USB
2. No celular: selecione "Transferência de arquivos" (MTP)
3. Copie o `.apk` para qualquer pasta no celular

**Bluetooth:**
1. Ative o Bluetooth no PC e no celular
2. Clique com botão direito no `.apk` → Enviar para → Dispositivo Bluetooth

---

### Passo 2 — Abra o arquivo no celular

No gerenciador de arquivos do celular, navegue até a pasta onde baixou o APK e toque nele.

---

### Passo 3 — Permitir instalação (apenas na primeira vez)

O Android bloqueia por padrão apps fora da Play Store. O processo para permitir varia por versão:

**Android 8, 9, 10, 11, 12, 13, 14 (mais comum):**
1. Aparece aviso: *"Por segurança, seu celular não tem permissão para instalar apps desconhecidos"*
2. Toque em **Configurações**
3. Ative **"Permitir desta fonte"** para o gerenciador de arquivos
4. Volte e tente instalar novamente

**Se não aparecer o botão Configurações:**
- Configurações → Apps → Menu ⋮ → Acesso especial → Instalar apps desconhecidos
- Encontre "Gerenciador de arquivos" ou "Files" e ative

**Android 7 e anteriores:**
- Configurações → Segurança → **Fontes desconhecidas** → Ativar
- Confirme o aviso

**Samsung (One UI):**
- Configurações → Biometria e segurança → Instalar apps desconhecidos
- Selecione o app gerenciador de arquivos → Permitir

---

### Passo 4 — Instalar

1. Toque **Instalar**
2. Aguarde ~10 segundos
3. Toque **Abrir** ou procure o ícone 🌿 na tela inicial

---

## 🔄 Atualizar o APK

Para instalar uma nova versão:
1. Rode `bash build-apk.sh` novamente (usa o mesmo `gin-lab-key.keystore`)
2. Transfira e instale o novo `gin-aromatics-lab.apk`
3. O Android substitui o anterior automaticamente (sem perder dados)

> **⚠️ Importante:** Se perder o `gin-lab-key.keystore`, precisará desinstalar
> o app antes de instalar a nova versão (o Android rejeita APKs com assinatura diferente).

---

## 🔑 Sobre o Keystore

O arquivo `gin-lab-key.keystore` é a **assinatura digital do seu APK**.

- É gerado automaticamente na primeira execução
- **Guarde em local seguro** (Google Drive, pen drive, backup)
- Sem ele, não é possível atualizar o APK sem reinstalar
- A senha padrão é `GinLab@2025` — pode mudar em `build-apk.sh`

---

## 📊 Diferença entre APK e PWA instalado via browser

| | APK (build-apk.sh) | PWA (via Chrome) |
|---|---|---|
| Aparece na Play Store | Não | Não |
| Ícone na tela inicial | ✓ | ✓ |
| Funciona offline | ✓ | ✓ |
| Notificações push | ✓ (futuro) | Limitado |
| Atualização automática | Via repositório | Automática |
| Tamanho | ~5MB | ~0 (carrega do servidor) |
| Distribuição | Via arquivo | Via link |

Ambos funcionam identicamente para o Gin Aromatics Lab.

---

*Gin Aromatics Lab · github.com/RodrigoVassoler/GINSMITH*
