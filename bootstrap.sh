#!/usr/bin/env bash
# One-liner: curl -sL https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/main/bootstrap.sh | bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/main"
SCRIPT="$HOME/setup-wsl.sh"

echo "Baixando setup-wsl.sh..."
curl -fsSL --connect-timeout 10 --max-time 60 "$REPO/setup-wsl.sh" -o "$SCRIPT"
chmod +x "$SCRIPT"
bash "$SCRIPT"
