#!/usr/bin/env bash
# One-liner: curl -sL https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/master/bootstrap.sh | bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/master"
SCRIPT="$HOME/setup-wsl.sh"

echo "Baixando setup-wsl.sh..."
curl -fsSL "$REPO/setup-wsl.sh" -o "$SCRIPT"
chmod +x "$SCRIPT"
bash "$SCRIPT"
