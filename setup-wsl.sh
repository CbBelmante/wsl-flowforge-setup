#!/usr/bin/env bash
# ============================================================
# WSL2 Dev Setup — One-Shot Installer
# Roda DENTRO do Ubuntu/WSL2 após o "wsl --install" + criação de usuário
# Uso: bash setup-wsl.sh
# ============================================================

set -euo pipefail

# Evita prompts interativos do apt/dpkg (ex.: o needrestart do Ubuntu 22.04+
# perguntando quais serviços reiniciar) — sem isso o script pode travar
# esperando uma resposta que ninguém vê, mesma classe de bug do winget.
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Aborta qualquer "git clone/fetch" via HTTPS se a velocidade cair abaixo de
# 1KB/s por 30s seguidos — sem isso, uma conexão que trava no meio (inclusive
# dentro de instaladores de terceiro como o do Oh My Zsh, que herdam essas
# variáveis) deixa o script pendurado pra sempre, sem erro e sem timeout.
export GIT_HTTP_LOW_SPEED_LIMIT=1000
export GIT_HTTP_LOW_SPEED_TIME=30

# --- Cores ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step=0
total=14

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
verify() { echo -e "${CYAN}  🔍 Pra conferir você mesmo, rode: $1${NC}"; }

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
echo -e "${CYAN}  Isso pode levar alguns minutos na primeira vez. Aguarde...${NC}"
sudo apt update && sudo apt upgrade -y
ok "Sistema atualizado"
echo "  $(lsb_release -d 2>/dev/null | cut -f2 | xargs)"
verify "lsb_release -a"

# ============================================================
# 2. Ferramentas básicas
# ============================================================
banner "Instalando ferramentas básicas"
sudo apt install -y curl wget git unzip build-essential
ok "Ferramentas básicas instaladas"
echo "  $(curl --version | head -1)"
echo "  $(git --version)"
echo "  $(wget --version | head -1)"
verify "curl --version; git --version; wget --version"

# ============================================================
# 3. Identidade Git (nome + email)
# ============================================================
banner "Configurando identidade Git"

GIT_NAME=$(git config --global user.name 2>/dev/null || true)
GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)

if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
  ok "Git: $GIT_NAME <$GIT_EMAIL>"
else
  echo -e "  ${CYAN}Preencha seus dados para commits:${NC}"
  read -rp "  Seu nome: " GIT_NAME < /dev/tty
  read -rp "  Seu email: " GIT_EMAIL < /dev/tty
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  ok "Git configurado: $GIT_NAME <$GIT_EMAIL>"
fi
verify "git config --global --list | grep 'user\\.'"

# ============================================================
# 4. Chave SSH (GitHub)
# ============================================================
banner "Gerando chave SSH"

SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_PUB=""
if [ -f "$SSH_KEY.pub" ]; then
  warn "Chave SSH já existe"
  SSH_PUB=$(cat "$SSH_KEY.pub")
else
  GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
  if [ -n "$GIT_EMAIL" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add "$SSH_KEY" 2>/dev/null
    SSH_PUB=$(cat "$SSH_KEY.pub")
    ok "Chave SSH gerada"
  else
    warn "Email do Git nao configurado — gere a chave depois com:"
    echo "    ssh-keygen -t ed25519 -C \"seu@email.com\""
  fi
fi
if [ -f "$SSH_KEY.pub" ]; then
  echo "  $(ssh-keygen -lf "$SSH_KEY.pub")"
  verify "ssh-keygen -lf ~/.ssh/id_ed25519.pub"
fi

# ============================================================
# 5. Zsh
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
echo "  $(zsh --version)"
echo "  shell padrão (só vale a partir do próximo login): $(getent passwd "$USER" | cut -d: -f7)"
verify "zsh --version; getent passwd \$USER | cut -d: -f7"

# ============================================================
# 6. Oh My Zsh
# ============================================================
banner "Instalando Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  warn "Oh My Zsh já existe, pulando..."
else
  RUNZSH=no CHSH=no timeout 120 sh -c "$(curl -fsSL --connect-timeout 10 --max-time 60 https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
# Se o curl dentro do $(...) falhar, sh -c "" roda um comando vazio e retorna
# sucesso mesmo sem instalar nada — por isso o "ok" só vale depois de checar o arquivo.
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  ok "Oh My Zsh instalado"
else
  fail "Oh My Zsh não confirmou a instalação — rode de novo ou instale manualmente"
fi
echo "  $(test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" && echo 'encontrado em ~/.oh-my-zsh')"
verify "ls ~/.oh-my-zsh/oh-my-zsh.sh"

# ============================================================
# 7. Powerlevel10k
# ============================================================
banner "Instalando Powerlevel10k"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
  warn "Powerlevel10k já existe, pulando..."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"

REPO_BASE="https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/main"
if [ ! -f "$HOME/.p10k.zsh" ]; then
  curl -fsSL --connect-timeout 10 --max-time 60 "$REPO_BASE/.p10k.zsh" -o "$HOME/.p10k.zsh"
  ok "Config p10k aplicada (rainbow + nerd fonts)"
else
  warn "Config p10k ja existe, mantendo a atual"
fi
if ! grep -qF 'p10k.zsh' "$HOME/.zshrc"; then
  echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$HOME/.zshrc"
fi
if [ -f "$P10K_DIR/powerlevel10k.zsh-theme" ] && grep -qF 'powerlevel10k/powerlevel10k' "$HOME/.zshrc"; then
  ok "Powerlevel10k instalado e configurado"
else
  fail "Powerlevel10k não confirmou — tema ou arquivo do zshrc ausente, confira manualmente"
fi
echo "  $(grep '^ZSH_THEME=' "$HOME/.zshrc")"
verify 'grep ZSH_THEME ~/.zshrc; ls "$ZSH_CUSTOM/themes/powerlevel10k"'

# ============================================================
# 8. Plugins Zsh (autosuggestions + syntax-highlighting)
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
if [ -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ] && [ -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ] \
  && grep -qF 'zsh-autosuggestions' "$HOME/.zshrc"; then
  ok "Plugins instalados e ativados"
else
  fail "Algum plugin não confirmou — confira as pastas e o plugins=(...) do zshrc"
fi
echo "  $(grep '^plugins=' "$HOME/.zshrc")"
verify 'grep plugins= ~/.zshrc'

# ============================================================
# 9. PATH extras no .zshrc
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
# Grava no .zshrc pra shells futuros, mas também aplica agora — senão os
# comandos "command -v" das próximas etapas neste MESMO script dariam falso
# negativo (binário instalado em ~/.local/bin, mas ainda fora do PATH atual).
export PATH="$HOME/.local/bin:/snap/bin:$PATH"
if grep -qF '.local/bin' "$HOME/.zshrc"; then
  ok "PATH confirmado no ~/.zshrc"
else
  fail "PATH não confirmou no ~/.zshrc — confira manualmente"
fi
echo "  $(grep -A1 'PATH extras' "$HOME/.zshrc" | tail -1)"
verify "grep -A1 'PATH extras' ~/.zshrc"

# ============================================================
# 10. tmux
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
verify "tmux -V"

# ============================================================
# 11. GitHub CLI
# ============================================================
banner "Instalando GitHub CLI"
if command -v gh &>/dev/null; then
  warn "GitHub CLI já instalado: $(gh --version | head -1)"
else
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- --timeout=15 --tries=1 https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update && sudo apt install -y gh
  ok "GitHub CLI instalado"
fi
echo "  $(gh --version | head -1)"
verify "gh --version"

# ============================================================
# 12. Node.js (via nvm)
# ============================================================
banner "Instalando Node.js (via nvm)"
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  warn "nvm já instalado"
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
else
  curl -fsSL --connect-timeout 10 --max-time 60 https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
fi
# O instalador do nvm decide sozinho entre .bashrc/.zshrc olhando $SHELL —
# mas nesse ponto do script $SHELL ainda mostra bash (o chsh da etapa 5 só
# vale a partir do PRÓXIMO login), então ele grava no .bashrc, que o zsh
# nunca lê. Resultado: nvm/node/npm/claude somem numa sessão zsh nova.
# Garantimos explicitamente que o .zshrc também tenha essas linhas.
if ! grep -qF 'NVM_DIR' "$HOME/.zshrc" 2>/dev/null; then
  {
    echo ''
    echo '# --- nvm ---'
    echo 'export NVM_DIR="$HOME/.nvm"'
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
  } >> "$HOME/.zshrc"
fi
if command -v node &>/dev/null; then
  warn "Node.js já instalado: $(node -v)"
else
  # nvm é função de shell, não binário — pra dar timeout nela, rodamos numa
  # subshell isolada via "timeout bash -c", que herda o NVM_DIR já exportado.
  # Só que isso isola o PATH que o nvm ajusta lá dentro, então depois de
  # instalar, rodamos "nvm use" de novo aqui fora (rápido, local, sem rede)
  # pra puxar o PATH certo pro shell principal do script.
  timeout 180 bash -c '. "$NVM_DIR/nvm.sh"; nvm install --lts'
  nvm use --lts >/dev/null 2>&1 || true
  if command -v node &>/dev/null; then
    ok "Node.js $(node -v) instalado"
  else
    fail "nvm install rodou mas node não ficou disponível — confira manualmente"
  fi
fi
echo "  node: $(node -v)  npm: $(npm -v)"
echo "  $(grep -c 'NVM_DIR' "$HOME/.zshrc" 2>/dev/null || echo 0) linha(s) de nvm no .zshrc"
verify "node -v; npm -v; grep NVM_DIR ~/.zshrc"

# ============================================================
# 13. Claude Code
# ============================================================
banner "Instalando Claude Code"
if command -v claude &>/dev/null; then
  warn "Claude Code já instalado: $(claude --version 2>/dev/null || echo '?')"
else
  timeout 180 npm install -g @anthropic-ai/claude-code
  if command -v claude &>/dev/null; then
    ok "Claude Code instalado"
  else
    fail "npm install rodou mas claude não ficou disponível no PATH — confira manualmente"
  fi
fi
echo "  $(claude --version 2>/dev/null || echo 'não respondeu ainda — pode precisar de um shell novo')"
verify "claude --version"

# ============================================================
# 14. FlowForge
# ============================================================
banner "Instalando FlowForge"
if command -v flowforge &>/dev/null; then
  warn "FlowForge já instalado: $(flowforge version 2>/dev/null || echo '?')"
else
  # Por padrão o instalador do FlowForge grava em /usr/local/bin, que exige
  # sudo (e a gente não roda ele com sudo). Manda instalar em ~/.local/bin
  # (já no PATH desde a etapa 9) pra não precisar de privilégio nenhum.
  mkdir -p "$HOME/.local/bin"
  # O curl já tem timeout de download; o "timeout" externo cobre o instalador
  # em si, que pode fazer mais chamadas de rede depois de receber o script.
  FLOWFORGE_INSTALL_DIR="$HOME/.local/bin" timeout 120 bash -c 'curl -fsSL --connect-timeout 10 --max-time 60 https://get.flowforgesoft.com/install.sh | sh'
  hash -r
  if command -v flowforge &>/dev/null; then
    ok "FlowForge instalado"
  else
    fail "Instalador rodou mas flowforge não ficou disponível no PATH — confira manualmente"
  fi
fi
echo "  $(flowforge version 2>/dev/null || echo 'não respondeu ainda — pode precisar de um shell novo')"
verify "flowforge version"

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
echo "  Proximos passos:"
echo ""
echo -e "  ${YELLOW}1.${NC} Feche esta janela e abra o Ubuntu de novo (p10k ja esta configurado)"
echo -e "  ${YELLOW}2.${NC} Adicione sua chave SSH no GitHub:"
echo "        https://github.com/settings/ssh/new"
if [ -n "$SSH_PUB" ]; then
  echo ""
  echo -e "  ${YELLOW}┌─────────────────────────────────────────────────────┐${NC}"
  echo -e "  ${YELLOW}│  Sua chave SSH (copie e cole no GitHub):            │${NC}"
  echo -e "  ${YELLOW}└─────────────────────────────────────────────────────┘${NC}"
  echo -e "  ${CYAN}${SSH_PUB}${NC}"
  echo ""
fi
echo -e "  ${YELLOW}3.${NC} Faca login no GitHub CLI:"
echo "        gh auth login"
echo -e "  ${YELLOW}4.${NC} Rode o doctor:"
echo "        flowforge doctor"
echo ""
echo -e "  ${YELLOW}Quer conferir tudo de uma vez? Rode:${NC}"
echo -e "  ${CYAN}zsh --version; tmux -V; gh --version; node -v; claude --version; flowforge version${NC}"
echo ""
