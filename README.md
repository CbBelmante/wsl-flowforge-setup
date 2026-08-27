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

### 1. No Windows

Baixe os dois arquivos e coloque na mesma pasta. Depois:

1. Clique direito no PowerShell → **Executar como administrador**
2. Navegue ate a pasta:
   ```powershell
   cd C:\Users\SeuUsuario\Downloads
   ```
3. Rode:
   ```powershell
   powershell -ExecutionPolicy Bypass -File setup-windows.ps1
   ```
4. **Reinicie o PC** quando pedir

### 2. Dentro do Ubuntu/WSL

Apos o reboot, abra **Ubuntu** no menu Iniciar (vai pedir pra criar usuario e senha na primeira vez).

Depois rode:

```bash
bash ~/setup-wsl.sh
```

Se o script nao estiver no `~/`, baixe manualmente:

```bash
curl -fsSL https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/master/setup-wsl.sh -o ~/setup-wsl.sh
bash ~/setup-wsl.sh
```

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

## Rodar de novo

Os scripts sao idempotentes — se algo ja estiver instalado, ele pula automaticamente. Pode rodar quantas vezes quiser sem medo.
