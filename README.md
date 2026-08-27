# WSL FlowForge Setup

Setup automatizado para montar um ambiente de desenvolvimento completo no Windows usando WSL2 + Ubuntu. Dois comandos, zero configuracao manual.

## O que instala

### Parte Windows (`setup-windows.ps1`)
- Verifica virtualizacao na BIOS (com instrucoes se desativada)
- WSL2 + Ubuntu
- Windows Terminal (via winget)
- Fontes MesloLGS NF (instaladas no sistema + registradas)
- Configura fonte automaticamente no Windows Terminal

### Parte WSL (`setup-wsl.sh`)
- Ferramentas basicas (curl, wget, git, unzip, build-essential)
- Identidade Git (pede nome + email)
- Chave SSH ed25519 (gera e mostra pra copiar no GitHub)
- Zsh como shell padrao
- Oh My Zsh + Powerlevel10k (tema rainbow, ja configurado sem wizard)
- Plugins: zsh-autosuggestions, zsh-syntax-highlighting
- tmux
- Node.js (via nvm)
- GitHub CLI
- Claude Code
- FlowForge

## Como usar

### 1. No Windows (PowerShell como Administrador)

```powershell
irm https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/master/setup-windows.ps1 | iex
```

> Instala WSL2 + Ubuntu, Windows Terminal, fontes e configura tudo automaticamente.
> Reinicie o PC quando pedir.

### 2. Dentro do Ubuntu/WSL

Apos o reboot, abra **Ubuntu** no menu Iniciar (vai pedir pra criar usuario e senha na primeira vez).

```bash
curl -sL https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/master/bootstrap.sh | bash
```

> Configura git, gera chave SSH, instala zsh + p10k + Node.js + Claude Code + FlowForge.
> A chave SSH aparece no final — copie e adicione em https://github.com/settings/ssh/new

### 3. Pos-setup

```bash
# Adicione a chave SSH no GitHub (link acima)

# Login no GitHub CLI
gh auth login

# Verificar FlowForge
flowforge doctor
```

## Requisitos

- Windows 10 (build 19041+) ou Windows 11
- PowerShell como Administrador (para a parte 1)
- Conexao com a internet
- **Virtualizacao habilitada na BIOS** (o script verifica automaticamente)

### Virtualizacao na BIOS

O WSL2 precisa de virtualizacao de hardware habilitada. A maioria dos PCs ja vem com isso ligado, mas se o script avisar que nao esta ativo:

1. Reinicie o PC e entre na BIOS (geralmente **F2**, **F10**, **Del** ou **Esc** ao ligar)
2. Procure a opcao:
   - **Intel**: `Intel Virtualization Technology (VT-x)` → **Enabled**
   - **AMD**: `SVM Mode` ou `AMD-V` → **Enabled**
3. Locais comuns: `Advanced → CPU Configuration`, `Security → Virtualization`, ou `BIOS Features`
4. Salve com **F10** e reinicie
5. Rode o script de novo

## Rodar de novo

Os scripts sao idempotentes — se algo ja estiver instalado, ele pula automaticamente. Pode rodar quantas vezes quiser sem medo.
