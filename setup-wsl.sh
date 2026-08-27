#!/usr/bin/env bash
# ============================================================
# WSL2 Dev Setup — One-Shot Installer
# Roda DENTRO do Ubuntu/WSL2 após o "wsl --install" + criação de usuário
# Uso: bash setup-wsl.sh
# ============================================================

set -euo pipefail

# --- Cores ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step=0
total=12

banner() {
  step=$((step + 1))
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}[$step/$total]${NC} $1"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

warn() { echo -e "${YELLOW}⚠  $1${NC}"; }
ok()   { echo -e "${GREEN}✔  $1${NC}"; }
fail() { echo -e "${RED}✖  $1${NC}"; }

# --- Checar se está rodando dentro do WSL ---
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  fail "Este script deve ser executado dentro do WSL2 (Ubuntu)."
  exit 1
fi

echo ""
echo -e "${CYAN}${BOLD}"
echo "  ███████╗██╗      ██████╗ ██╗    ██╗███████╗ ██████╗ ██████╗  ██████╗ ███████╗"
echo "  ██╔════╝██║     ██╔═══██╗██║    ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝"
echo "  █████╗  ██║     ██║   ██║██║ █╗ ██║█████╗  ██║   ██║██████╔╝██║  ███╗█████╗  "
echo "  ██╔══╝  ██║     ██║   ██║██║███╗██║██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  "
echo "  ██║     ███████╗╚██████╔╝╚███╔███╔╝██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗"
echo "  ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo ""
echo "  ███████╗███████╗████████╗██╗   ██╗██████╗ "
echo "  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
echo "  ███████╗█████╗     ██║   ██║   ██║██████╔╝"
echo "  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ "
echo "  ███████║███████╗   ██║   ╚██████╔╝██║     "
echo "  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     "
echo -e "${NC}"
echo -e "  ${BLUE}WSL2 Dev Environment — One-Shot Installer${NC}"
echo ""
echo "  Vai instalar: apt tools, zsh, oh-my-zsh, powerlevel10k,"
echo "  plugins zsh, tmux, Node.js, GitHub CLI, Claude Code, FlowForge"
echo ""
read -rp "Aperta Enter pra começar (Ctrl+C pra cancelar)... " < /dev/tty

# ============================================================
# 1. Atualizar o sistema
# ============================================================
banner "Atualizando o sistema"
sudo apt update && sudo apt upgrade -y
ok "Sistema atualizado"

# ============================================================
# 2. Ferramentas básicas
# ============================================================
banner "Instalando ferramentas básicas"
sudo apt install -y curl wget git unzip build-essential
ok "Ferramentas básicas instaladas"

# ============================================================
# 3. Zsh
# ============================================================
banner "Instalando Zsh"
if command -v zsh &>/dev/null; then
  warn "Zsh já instalado: $(zsh --version)"
else
  sudo apt install -y zsh
fi
if [ "$(basename "$SHELL")" != "zsh" ]; then
  sudo chsh -s "$(which zsh)" "$USER"
  ok "Zsh instalado e definido como shell padrão"
else
  ok "Zsh já é o shell padrão"
fi

# ============================================================
# 4. Oh My Zsh
# ============================================================
banner "Instalando Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  warn "Oh My Zsh já existe, pulando..."
else
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ok "Oh My Zsh instalado"

# ============================================================
# 5. Powerlevel10k
# ============================================================
banner "Instalando Powerlevel10k"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
  warn "Powerlevel10k já existe, pulando..."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
ok "Powerlevel10k instalado"

# ============================================================
# 6. Plugins Zsh (autosuggestions + syntax-highlighting)
# ============================================================
banner "Instalando plugins Zsh"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
fi

sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
ok "Plugins instalados e ativados"

# ============================================================
# 7. PATH extras no .zshrc
# ============================================================
banner "Configurando PATH"
PATH_LINE='export PATH="$HOME/.local/bin:/snap/bin:$PATH"'
if ! grep -qF '.local/bin' "$HOME/.zshrc"; then
  {
    echo ''
    echo '# --- PATH extras ---'
    echo "$PATH_LINE"
  } >> "$HOME/.zshrc"
  ok "PATH atualizado (~/.local/bin e /snap/bin)"
else
  warn "PATH já configurado, pulando..."
fi

# ============================================================
# 8. tmux
# ============================================================
banner "Instalando tmux"
if command -v tmux &>/dev/null; then
  warn "tmux já instalado: $(tmux -V)"
else
  sudo apt install -y tmux
fi
TMUX_MAJOR=$(tmux -V | grep -oP '\d+' | head -1)
if [ "$TMUX_MAJOR" -lt 3 ] 2>/dev/null; then
  warn "tmux versão $(tmux -V | awk '{print $2}') — recomendado 3.0+"
else
  ok "tmux $(tmux -V | awk '{print $2}') instalado"
fi

# ============================================================
# 9. GitHub CLI
# ============================================================
banner "Instalando GitHub CLI"
if command -v gh &>/dev/null; then
  warn "GitHub CLI já instalado: $(gh --version | head -1)"
else
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update && sudo apt install -y gh
  ok "GitHub CLI instalado"
fi

# ============================================================
# 10. Node.js (via nvm)
# ============================================================
banner "Instalando Node.js (via nvm)"
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  warn "nvm já instalado"
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
else
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
fi
if command -v node &>/dev/null; then
  warn "Node.js já instalado: $(node -v)"
else
  nvm install --lts
  ok "Node.js $(node -v) instalado"
fi

# ============================================================
# 11. Claude Code
# ============================================================
banner "Instalando Claude Code"
if command -v claude &>/dev/null; then
  warn "Claude Code já instalado: $(claude --version 2>/dev/null || echo '?')"
else
  npm install -g @anthropic-ai/claude-code
  ok "Claude Code instalado"
fi

# ============================================================
# 12. FlowForge
# ============================================================
banner "Instalando FlowForge"
if command -v flowforge &>/dev/null; then
  warn "FlowForge já instalado: $(flowforge version 2>/dev/null || echo '?')"
else
  curl -fsSL https://get.flowforgesoft.com/install.sh | sh
  ok "FlowForge instalado"
fi

# ============================================================
# Resumo final
# ============================================================
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ██████╗  ██████╗ ███╗   ██╗███████╗██╗"
echo "  ██╔══██╗██╔═══██╗████╗  ██║██╔════╝██║"
echo "  ██║  ██║██║   ██║██╔██╗ ██║█████╗  ██║"
echo "  ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ╚═╝"
echo "  ██████╔╝╚██████╔╝██║ ╚████║███████╗██╗"
echo "  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝"
echo -e "${NC}"
echo "  Próximos passos:"
echo ""
echo -e "  ${YELLOW}1.${NC} Feche esta janela e abra o Ubuntu de novo"
echo -e "  ${YELLOW}2.${NC} O wizard do Powerlevel10k vai abrir — siga as instruções"
echo -e "  ${YELLOW}3.${NC} Faça login no GitHub:"
echo "        gh auth login"
echo -e "  ${YELLOW}4.${NC} Rode o doctor:"
echo "        flowforge doctor"
echo ""
echo -e "  ${YELLOW}FONTES:${NC} Instale a MesloLGS NF no WINDOWS (não no WSL)."
echo "  Baixe as 4 .ttf de:"
echo "  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
echo "  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
echo "  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
echo "  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
echo ""
echo "  Clique direito → 'Instalar para todos os usuários'"
echo "  Configure no Windows Terminal: Aparência → Fonte → MesloLGS NF"
echo ""
