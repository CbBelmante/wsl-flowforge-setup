# ============================================================
# WSL2 Dev Setup — Parte 1: Windows
# Roda no PowerShell COMO ADMINISTRADOR
# Uso: clique direito no arquivo → "Executar com PowerShell"
#      ou: powershell -ExecutionPolicy Bypass -File setup-windows.ps1
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Step($num, $total, $msg) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "[$num/$total] $msg" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
}

# --- Checar se é administrador ---
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "✖  Execute este script como Administrador!" -ForegroundColor Red
    Write-Host "   Clique direito no PowerShell → 'Executar como administrador'" -ForegroundColor Yellow
    Read-Host "Aperte Enter pra sair"
    exit 1
}

Write-Host ""
Write-Host "  ███████╗██╗      ██████╗ ██╗    ██╗███████╗ ██████╗ ██████╗  ██████╗ ███████╗" -ForegroundColor Cyan
Write-Host "  ██╔════╝██║     ██╔═══██╗██║    ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝" -ForegroundColor Cyan
Write-Host "  █████╗  ██║     ██║   ██║██║ █╗ ██║█████╗  ██║   ██║██████╔╝██║  ███╗█████╗  " -ForegroundColor Cyan
Write-Host "  ██╔══╝  ██║     ██║   ██║██║███╗██║██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  " -ForegroundColor Cyan
Write-Host "  ██║     ███████╗╚██████╔╝╚███╔███╔╝██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗" -ForegroundColor Cyan
Write-Host "  ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ███████╗███████╗████████╗██╗   ██╗██████╗ " -ForegroundColor Cyan
Write-Host "  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗" -ForegroundColor Cyan
Write-Host "  ███████╗█████╗     ██║   ██║   ██║██████╔╝" -ForegroundColor Cyan
Write-Host "  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ " -ForegroundColor Cyan
Write-Host "  ███████║███████╗   ██║   ╚██████╔╝██║     " -ForegroundColor Cyan
Write-Host "  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     " -ForegroundColor Cyan
Write-Host ""
Write-Host "  WSL2 Dev Environment — Parte 1 (Windows)" -ForegroundColor Blue
Write-Host ""
Write-Host "  Vai instalar: WSL2, Ubuntu, Windows Terminal, fontes MesloLGS NF"
Write-Host ""
Read-Host "Aperta Enter pra começar (Ctrl+C pra cancelar)"

$total = 6

# ============================================================
# 1. Verificar virtualizacao
# ============================================================
Write-Step 1 $total "Verificando virtualizacao do processador"

$virtEnabled = $false
try {
    $cpu = Get-CimInstance -ClassName Win32_Processor
    if ($cpu.VirtualizationFirmwareEnabled) {
        $virtEnabled = $true
    }
} catch {}

if ($virtEnabled) {
    Write-Host "✔  Virtualizacao habilitada no processador" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "✖  VIRTUALIZACAO NAO DETECTADA!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  O WSL2 precisa de virtualizacao habilitada na BIOS." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Como habilitar:" -ForegroundColor Cyan
    Write-Host "    1. Reinicie o PC e entre na BIOS (geralmente F2, F10, Del ou Esc ao ligar)" -ForegroundColor White
    Write-Host "    2. Procure uma dessas opcoes:" -ForegroundColor White
    Write-Host "       - Intel: 'Intel Virtualization Technology (VT-x)' → Enabled" -ForegroundColor White
    Write-Host "       - AMD:   'SVM Mode' ou 'AMD-V' → Enabled" -ForegroundColor White
    Write-Host "    3. Salve (F10) e reinicie" -ForegroundColor White
    Write-Host "    4. Rode este script de novo" -ForegroundColor White
    Write-Host ""
    Write-Host "  Locais comuns na BIOS:" -ForegroundColor Cyan
    Write-Host "    - Advanced → CPU Configuration" -ForegroundColor White
    Write-Host "    - Security → Virtualization" -ForegroundColor White
    Write-Host "    - BIOS Features → Virtualization" -ForegroundColor White
    Write-Host ""
    $continuar = Read-Host "Quer continuar mesmo assim? (s/N)"
    if ($continuar -ne "s" -and $continuar -ne "S") {
        Write-Host "  Abortado. Habilite a virtualizacao e rode de novo." -ForegroundColor Yellow
        Read-Host "Aperte Enter pra sair"
        exit 1
    }
    Write-Host "⚠  Continuando sem virtualizacao — o WSL2 pode nao funcionar" -ForegroundColor Yellow
}

# ============================================================
# 2. Instalar WSL2 + Ubuntu
# ============================================================
Write-Step 2 $total "Instalando WSL2 + Ubuntu"

$wslInstalled = $false
try {
    $wslList = wsl --list --quiet 2>$null
    if ($wslList -match "Ubuntu") {
        $wslInstalled = $true
        Write-Host "⚠  Ubuntu já instalado no WSL" -ForegroundColor Yellow
    }
} catch {}

if (-not $wslInstalled) {
    Write-Host "Instalando WSL2 com Ubuntu (pode demorar)..." -ForegroundColor Cyan
    wsl --install -d Ubuntu
    Write-Host "✔  WSL2 + Ubuntu instalado" -ForegroundColor Green
    $needsReboot = $true
} else {
    $needsReboot = $false
}

# ============================================================
# 3. Windows Terminal (via winget)
# ============================================================
Write-Step 3 $total "Verificando Windows Terminal"

$hasWinget = Get-Command winget -ErrorAction SilentlyContinue
if ($hasWinget) {
    $wtInstalled = winget list --id Microsoft.WindowsTerminal 2>$null
    if ($wtInstalled -match "WindowsTerminal") {
        Write-Host "⚠  Windows Terminal já instalado" -ForegroundColor Yellow
    } else {
        winget install -e --id Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
        Write-Host "✔  Windows Terminal instalado" -ForegroundColor Green
    }
} else {
    Write-Host "⚠  winget não encontrado — instale o Windows Terminal manualmente" -ForegroundColor Yellow
    Write-Host "   https://aka.ms/terminal" -ForegroundColor Cyan
}

# ============================================================
# 4. Fontes MesloLGS NF
# ============================================================
Write-Step 4 $total "Instalando fontes MesloLGS NF"

$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$fontsInstalled = Test-Path "$fontDir\MesloLGS NF Regular.ttf"

if ($fontsInstalled) {
    Write-Host "⚠  Fontes MesloLGS NF já instaladas" -ForegroundColor Yellow
} else {
    $fontBaseUrl = "https://github.com/romkatv/powerlevel10k-media/raw/master"
    $fontNames = @(
        "MesloLGS NF Regular.ttf",
        "MesloLGS NF Bold.ttf",
        "MesloLGS NF Italic.ttf",
        "MesloLGS NF Bold Italic.ttf"
    )

    $tempDir = "$env:TEMP\meslo-fonts"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    foreach ($font in $fontNames) {
        $url = "$fontBaseUrl/$($font -replace ' ', '%20')"
        $dest = "$tempDir\$font"
        Write-Host "  Baixando $font..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    }

    $shellApp = New-Object -ComObject Shell.Application
    $fontsFolder = $shellApp.Namespace(0x14)
    foreach ($font in $fontNames) {
        $fontsFolder.CopyHere("$tempDir\$font", 0x10)
    }

    Remove-Item -Recurse -Force $tempDir
    Write-Host "✔  Fontes instaladas" -ForegroundColor Green
}

# ============================================================
# 5. Copiar setup-wsl.sh pro WSL
# ============================================================
Write-Step 5 $total "Preparando script de setup interno"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wslScript = Join-Path $scriptDir "setup-wsl.sh"

if (Test-Path $wslScript) {
    if (-not $needsReboot) {
        $wslHome = (wsl -- bash -c 'echo $HOME' 2>$null).Trim()
        if ($wslHome) {
            $wslDest = wsl -- wslpath -u ($wslScript -replace '\\', '/')
            wsl -- cp "$wslDest" "$wslHome/setup-wsl.sh"
            wsl -- chmod +x "$wslHome/setup-wsl.sh"
            Write-Host "✔  setup-wsl.sh copiado para $wslHome/" -ForegroundColor Green
        } else {
            Write-Host "⚠  Não foi possível copiar — copie manualmente após o reboot" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠  WSL precisa de reboot primeiro — copie manualmente depois" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠  setup-wsl.sh não encontrado na mesma pasta" -ForegroundColor Yellow
    Write-Host "   Coloque os dois scripts na mesma pasta e rode de novo" -ForegroundColor Yellow
}

# ============================================================
# 6. Instruções finais
# ============================================================
Write-Step 6 $total "Concluído!"

Write-Host ""
Write-Host "  ██████╗  ██████╗ ███╗   ██╗███████╗██╗" -ForegroundColor Green
Write-Host "  ██╔══██╗██╔═══██╗████╗  ██║██╔════╝██║" -ForegroundColor Green
Write-Host "  ██║  ██║██║   ██║██╔██╗ ██║█████╗  ██║" -ForegroundColor Green
Write-Host "  ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ╚═╝" -ForegroundColor Green
Write-Host "  ██████╔╝╚██████╔╝██║ ╚████║███████╗██╗" -ForegroundColor Green
Write-Host "  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝" -ForegroundColor Green
Write-Host ""

if ($needsReboot) {
    Write-Host "  IMPORTANTE: Reinicie o PC para finalizar a instalação do WSL2" -ForegroundColor Red
    Write-Host ""
}

Write-Host "  Próximos passos:" -ForegroundColor Yellow
Write-Host ""
if ($needsReboot) {
    Write-Host "  1. Reinicie o PC" -ForegroundColor White
    Write-Host "  2. Abra 'Ubuntu' no menu Iniciar (vai pedir pra criar usuário)" -ForegroundColor White
    Write-Host "  3. Dentro do Ubuntu, rode:" -ForegroundColor White
} else {
    Write-Host "  1. Abra 'Ubuntu' no menu Iniciar (ou Windows Terminal → Ubuntu)" -ForegroundColor White
    Write-Host "  2. Dentro do Ubuntu, rode:" -ForegroundColor White
}
Write-Host ""
Write-Host "        bash ~/setup-wsl.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Depois configure no Windows Terminal:" -ForegroundColor Yellow
Write-Host "    Configurações → Ubuntu → Aparência → Fonte → MesloLGS NF" -ForegroundColor White
Write-Host ""
Read-Host "Aperte Enter pra sair"
