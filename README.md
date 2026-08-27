# WSL FlowForge Setup

Setup automatizado para montar um ambiente de desenvolvimento completo no Windows usando WSL2 + Ubuntu.

## O que instala

### Parte Windows (`setup-windows.ps1`)
- WSL2 + Ubuntu
- Windows Terminal (via winget)
- Fontes MesloLGS NF (para o Powerlevel10k funcionar bonito)

### Parte WSL (`setup-wsl.sh`)
- Ferramentas basicas (curl, wget, git, unzip, build-essential)
- Zsh como shell padrao
- Oh My Zsh + Powerlevel10k (tema)
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

> Instala WSL2 + Ubuntu, Windows Terminal, fontes e baixa o script pro WSL automaticamente.
> Reinicie o PC quando pedir.

### 2. Dentro do Ubuntu/WSL

Apos o reboot, abra **Ubuntu** no menu Iniciar (vai pedir pra criar usuario e senha na primeira vez).

```bash
curl -sL https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/master/bootstrap.sh | bash
```

> Instala zsh, p10k, plugins, tmux, Node.js, gh, Claude Code e FlowForge automaticamente.

### 3. Configurar fonte no Windows Terminal

1. Abra **Windows Terminal**
2. Configuracoes → Perfil **Ubuntu** → **Aparencia**
3. Fonte → **MesloLGS NF**
4. Tamanho → **11** (recomendado)
5. Salvar

## Proximos passos (manual)

Apos o setup terminar:

```bash
# Login no GitHub
gh auth login

# Verificar FlowForge
flowforge doctor

# Configurar git
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
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
