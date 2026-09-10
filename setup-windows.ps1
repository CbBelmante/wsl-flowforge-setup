# ============================================================
# FlowForge Setup — Parte 1: Windows
# Roda no PowerShell COMO ADMINISTRADOR
# One-liner: irm https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/main/setup-windows.ps1 | iex
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Step($num, $total, $msg) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "[$num/$total] $msg" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
}

# Roda winget em background com timeout. Existe pra que um prompt interativo
# perdido (ex.: aceite de termos de fonte na primeira execução) nunca prenda
# o script pra sempre — o job não tem console interativo, então ou o winget
# responde sozinho (com --accept-source-agreements) ou o job estoura o tempo
# e devolvemos $null pro chamador decidir o fallback manual.
function Invoke-WingetWithTimeout($wingetArgs, $timeoutSec) {
    $job = Start-Job -ScriptBlock {
        param($a)
        & winget @a 2>$null
    } -ArgumentList (,$wingetArgs)

    if (Wait-Job $job -Timeout $timeoutSec) {
        $output = Receive-Job $job
        Remove-Job $job -Force | Out-Null
        return $output
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue | Out-Null
        Remove-Job $job -Force -ErrorAction SilentlyContinue | Out-Null
        return $null
    }
}

# Mesma ideia do Invoke-WingetWithTimeout, só que genérico pra qualquer
# executável — usado onde um processo externo (ex.: wsl.exe) pode travar
# por motivo alheio ao comando interno que ele está rodando.
# $LASTEXITCODE não atravessa a fronteira do job sozinho — por isso o job
# captura o próprio código de saída e devolve num objeto junto com a saída.
function Invoke-ExeWithTimeout($exe, $exeArgs, $timeoutSec) {
    $job = Start-Job -ScriptBlock {
        param($e, $a)
        $out = & $e @a 2>$null
        [PSCustomObject]@{ Output = $out; ExitCode = $LASTEXITCODE }
    } -ArgumentList $exe, (,$exeArgs)

    if (Wait-Job $job -Timeout $timeoutSec) {
        $result = Receive-Job $job
        Remove-Job $job -Force | Out-Null
        return $result
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue | Out-Null
        Remove-Job $job -Force -ErrorAction SilentlyContinue | Out-Null
        return $null
    }
}

# wsl.exe emite UTF-16LE quando a saída é capturada (não é console real). No
# PowerShell 5.1 o encoding padrão de captura pode não bater com isso e
# corromper o texto — fazendo "-match Ubuntu" falhar mesmo com Ubuntu instalado.
# Por isso toda leitura de "wsl --list" passa por aqui, não por chamada direta.
function Get-WslDistroList {
    $prevEncoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        return (wsl --list --quiet 2>$null)
    } finally {
        [Console]::OutputEncoding = $prevEncoding
    }
}

# Mostra ao usuário o comando exato pra ele mesmo conferir o que essa etapa fez.
function Show-Verify($cmd) {
    Write-Host "  🔍 Pra conferir você mesmo, rode:" -ForegroundColor DarkCyan
    Write-Host "     $cmd" -ForegroundColor DarkGray
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

$total = 7

# ============================================================
# 1. Verificar virtualizacao
# ============================================================
Write-Step 1 $total "Verificando virtualizacao do processador"

$virtEnabled = $false
try {
    $cpu = Get-CimInstance -ClassName Win32_Processor -OperationTimeoutSec 10
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
Write-Host "  Valor bruto: VirtualizationFirmwareEnabled = $virtEnabled" -ForegroundColor DarkGray
Show-Verify '(Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled'

# ============================================================
# 2. Instalar WSL2 + Ubuntu
# ============================================================
Write-Step 2 $total "Instalando WSL2 + Ubuntu"

$wslInstalled = $false
try {
    $wslList = Get-WslDistroList
    if ($wslList -match "Ubuntu") {
        $wslInstalled = $true
        Write-Host "⚠  Ubuntu já instalado no WSL" -ForegroundColor Yellow
    }
} catch {}

$wslInstallFailed = $false
if (-not $wslInstalled) {
    # Kernel do WSL desatualizado é causa conhecida de "wsl --install" terminar
    # com sucesso sem registrar distro nenhuma — atualiza antes de tentar.
    try { wsl --update } catch {}

    Write-Host "Instalando WSL2 com Ubuntu — isso pode levar de 5 a 15 minutos," -ForegroundColor Cyan
    Write-Host "dependendo da internet. Não feche esta janela, mesmo sem novidade na tela." -ForegroundColor Cyan
    wsl --install -d Ubuntu
    $installExitCode = $LASTEXITCODE
    if ($installExitCode -ne 0) {
        $wslInstallFailed = $true
        Write-Host "✖  wsl --install terminou com erro (código $installExitCode) — a distro pode não ter sido registrada" -ForegroundColor Red
        Write-Host "   Rode manualmente pra ver o motivo completo: wsl --install -d Ubuntu" -ForegroundColor Yellow
    } else {
        Write-Host "✔  Comando de instalação rodou sem erro" -ForegroundColor Green
    }
    $needsReboot = $true
} else {
    $needsReboot = $false
}

if (-not $needsReboot) {
    Write-Host ""
    Write-Host "  Versão do WSL e distros instaladas:" -ForegroundColor DarkGray
    wsl --version
    wsl -l -v
} else {
    # "wsl --install" pode terminar com sucesso tendo feito só METADE do trabalho:
    # numa máquina sem o VirtualMachinePlatform habilitado antes, ele habilita o
    # componente e pede reboot — mas só registra a distro numa SEGUNDA chamada,
    # depois de reiniciar. Ninguém re-executa isso sozinho, então tratamos o
    # "rode de novo depois do reboot" como passo padrão, não como troubleshooting
    # condicional — ver instruções finais (etapa 7).
    if ($wslInstallFailed) {
        Write-Host "  ⚠  Além disso, o comando terminou com erro — é ainda mais provável que precise rodar de novo." -ForegroundColor Yellow
    } else {
        Write-Host "  (normal: numa máquina que nunca teve WSL, o registro da distro só completa" -ForegroundColor DarkGray
        Write-Host "   na SEGUNDA chamada de 'wsl --install -d Ubuntu', depois do reboot.)" -ForegroundColor DarkGray
    }
}
Show-Verify 'wsl --version; wsl -l -v'

# ============================================================
# 3. Windows Terminal (via winget)
# ============================================================
Write-Step 3 $total "Verificando Windows Terminal"

$hasWinget = Get-Command winget -ErrorAction SilentlyContinue
if ($hasWinget) {
    Write-Host "  Consultando o winget (pode levar alguns instantes na primeira vez)..." -ForegroundColor DarkGray
    $wtInstalled = Invoke-WingetWithTimeout @("list", "--id", "Microsoft.WindowsTerminal", "--accept-source-agreements") 60

    if ($null -eq $wtInstalled) {
        Write-Host "⚠  O winget não respondeu a tempo — instale manualmente:" -ForegroundColor Yellow
        Write-Host "   https://aka.ms/terminal" -ForegroundColor Cyan
    } elseif ($wtInstalled -match "WindowsTerminal") {
        Write-Host "⚠  Windows Terminal já instalado" -ForegroundColor Yellow
        Write-Host "  $($wtInstalled | Select-String WindowsTerminal)" -ForegroundColor DarkGray
    } else {
        Write-Host "  Instalando Windows Terminal (pode levar 1-2 minutos)..." -ForegroundColor DarkGray
        $installResult = Invoke-WingetWithTimeout @("install", "-e", "--id", "Microsoft.WindowsTerminal", "--accept-source-agreements", "--accept-package-agreements") 180
        if ($null -eq $installResult) {
            Write-Host "⚠  A instalação não confirmou a tempo — instale manualmente:" -ForegroundColor Yellow
            Write-Host "   https://aka.ms/terminal" -ForegroundColor Cyan
        } else {
            # O job pode terminar "sem timeout" mesmo assim tendo falhado (ex.: erro do
            # winget capturado como texto). Não basta o job ter respondido — reconsultamos
            # o estado real antes de declarar sucesso.
            $recheck = Invoke-WingetWithTimeout @("list", "--id", "Microsoft.WindowsTerminal", "--accept-source-agreements") 30
            if ($recheck -match "WindowsTerminal") {
                Write-Host "✔  Windows Terminal instalado (confirmado via winget list)" -ForegroundColor Green
            } else {
                Write-Host "⚠  O winget rodou mas não confirmamos a instalação — instale manualmente:" -ForegroundColor Yellow
                Write-Host "   https://aka.ms/terminal" -ForegroundColor Cyan
                Write-Host "  Saída do winget: $installResult" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host "⚠  winget não encontrado — instale o Windows Terminal manualmente" -ForegroundColor Yellow
    Write-Host "   https://aka.ms/terminal" -ForegroundColor Cyan
}
Show-Verify 'winget list --id Microsoft.WindowsTerminal'

# ============================================================
# 4. Fontes MesloLGS NF
# ============================================================
Write-Step 4 $total "Instalando fontes MesloLGS NF"

$sysFontDir = "$env:SystemRoot\Fonts"
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$fontsInstalled = Test-Path "$sysFontDir\MesloLGS NF Regular.ttf"

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
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 30
    }

    foreach ($font in $fontNames) {
        $src = "$tempDir\$font"
        Copy-Item $src -Destination "$sysFontDir\$font" -Force
        $fontTitle = $font -replace '\.ttf$', ' (TrueType)'
        New-ItemProperty -Path $regPath -Name $fontTitle -Value $font -PropertyType String -Force | Out-Null
        Write-Host "  ✔  $font" -ForegroundColor Green
    }

    Remove-Item -Recurse -Force $tempDir

    # Só declara sucesso depois de conferir que os 4 arquivos realmente estão
    # no destino — não basta o Copy-Item/New-ItemProperty não terem lançado erro.
    $allFontsPresent = $true
    foreach ($font in $fontNames) {
        if (-not (Test-Path "$sysFontDir\$font")) { $allFontsPresent = $false }
    }
    if ($allFontsPresent) {
        Write-Host "✔  Fontes instaladas em $sysFontDir e registradas no sistema" -ForegroundColor Green
    } else {
        Write-Host "⚠  Nem todas as fontes confirmaram no destino — confira manualmente" -ForegroundColor Yellow
    }
}
Write-Host "  Arquivo encontrado: $(Test-Path "$sysFontDir\MesloLGS NF Regular.ttf")" -ForegroundColor DarkGray
Show-Verify 'Test-Path "$env:SystemRoot\Fonts\MesloLGS NF Regular.ttf"'

# ============================================================
# 5. Configurar fonte no Windows Terminal
# ============================================================
Write-Step 5 $total "Configurando fonte no Windows Terminal"

$wtSettingsPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)

$wtSettings = $null
foreach ($p in $wtSettingsPaths) {
    if (Test-Path $p) { $wtSettings = $p; break }
}

if ($wtSettings) {
    try {
        $json = Get-Content $wtSettings -Raw | ConvertFrom-Json

        if (-not $json.profiles.defaults) {
            $json.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue ([PSCustomObject]@{}) -Force
        }

        $fontObj = [PSCustomObject]@{ face = "MesloLGS NF"; size = 11 }
        if ($json.profiles.defaults.PSObject.Properties["font"]) {
            $json.profiles.defaults.font = $fontObj
        } else {
            $json.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue $fontObj -Force
        }

        $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding UTF8

        # Relê o arquivo do zero — não confia que o Set-Content sem erro
        # significa que o valor certo realmente foi pro disco.
        $reread = Get-Content $wtSettings -Raw | ConvertFrom-Json
        if ($reread.profiles.defaults.font.face -eq "MesloLGS NF") {
            Write-Host "✔  Fonte MesloLGS NF configurada no Windows Terminal (confirmado no arquivo)" -ForegroundColor Green
        } else {
            Write-Host "⚠  Gravou o arquivo mas a fonte não confirmou na releitura — configure manualmente" -ForegroundColor Yellow
            Write-Host "  Configure manualmente: Configuracoes -> Aparencia -> Fonte -> MesloLGS NF" -ForegroundColor White
        }
    } catch {
        Write-Host "⚠  Nao foi possivel configurar automaticamente" -ForegroundColor Yellow
        Write-Host "  Configure manualmente: Configuracoes -> Aparencia -> Fonte -> MesloLGS NF" -ForegroundColor White
    }
} else {
    Write-Host "⚠  Windows Terminal nao encontrado — configure a fonte manualmente depois" -ForegroundColor Yellow
}
if ($wtSettings) {
    Show-Verify 'Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" | Select-String MesloLGS'
}

# ============================================================
# 6. Baixar setup-wsl.sh pro WSL
# ============================================================
Write-Step 6 $total "Baixando script de setup pro WSL"

$repoBase = "https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/main"

if (-not $needsReboot) {
    $downloadArgs = @("--", "bash", "-c", "curl -fsSL --connect-timeout 10 --max-time 60 $repoBase/setup-wsl.sh -o ~/setup-wsl.sh && chmod +x ~/setup-wsl.sh")
    Invoke-ExeWithTimeout "wsl" $downloadArgs 90 | Out-Null

    # Processo externo — $ErrorActionPreference=Stop não pega falha dele.
    # Só confiamos depois de checar o arquivo de fato, com o mesmo tipo de timeout.
    $checkResult = Invoke-ExeWithTimeout "wsl" @("--", "test", "-f", "~/setup-wsl.sh") 15
    if ($null -ne $checkResult -and $checkResult.ExitCode -eq 0) {
        Write-Host "✔  setup-wsl.sh baixado para ~/setup-wsl.sh dentro do WSL (confirmado)" -ForegroundColor Green
    } else {
        Write-Host "⚠  Não conseguimos confirmar o download — rode o comando abaixo dentro do Ubuntu depois:" -ForegroundColor Yellow
        Write-Host "   curl -fsSL --connect-timeout 10 --max-time 60 $repoBase/setup-wsl.sh -o ~/setup-wsl.sh && chmod +x ~/setup-wsl.sh" -ForegroundColor Cyan
    }
} else {
    Write-Host "⚠  WSL ainda nao esta pronto (precisa de reboot primeiro)" -ForegroundColor Yellow
    Write-Host "  Apos o reboot, o comando abaixo baixa e roda tudo automaticamente" -ForegroundColor White
}
if (-not $needsReboot) {
    Show-Verify 'wsl -- test -f ~/setup-wsl.sh && echo OK'
}

# ============================================================
# 7. Instruções finais
# ============================================================
Write-Step 7 $total "Concluído!"

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
    Write-Host "  2. Abra o PowerShell como Administrador e rode de novo:" -ForegroundColor White
    Write-Host "        wsl --install -d Ubuntu" -ForegroundColor Cyan
    Write-Host "     Numa máquina que nunca teve WSL, esse é o passo que REALMENTE registra" -ForegroundColor White
    Write-Host "     a distro — a primeira chamada, antes do reboot, só habilita o componente" -ForegroundColor White
    Write-Host "     do Windows. Pular esse passo é a causa nº1 do Ubuntu 'abrir e fechar na hora'." -ForegroundColor White
    Write-Host "  3. Confirme com 'wsl -l -v' — só abra o Ubuntu depois de ver 'Ubuntu' listado." -ForegroundColor White
    Write-Host "  4. Abra 'Ubuntu' no menu Iniciar (vai pedir pra criar usuario)" -ForegroundColor White
    Write-Host "  5. Dentro do Ubuntu, rode:" -ForegroundColor White
} else {
    Write-Host "  1. Abra 'Ubuntu' no menu Iniciar (ou Windows Terminal -> Ubuntu)" -ForegroundColor White
    Write-Host "  2. Rode:" -ForegroundColor White
}
Write-Host ""
Write-Host "     curl -sL https://raw.githubusercontent.com/CbBelmante/wsl-flowforge-setup/main/bootstrap.sh | bash" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Quer conferir tudo de uma vez? Rode:" -ForegroundColor Yellow
Write-Host "     wsl -l -v" -ForegroundColor Cyan
Write-Host "     winget list --id Microsoft.WindowsTerminal" -ForegroundColor Cyan
Write-Host "     Test-Path `"`$env:SystemRoot\Fonts\MesloLGS NF Regular.ttf`"" -ForegroundColor Cyan
Write-Host ""
Read-Host "Aperte Enter pra sair"
