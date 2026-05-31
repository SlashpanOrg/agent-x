# Agent-X Installer for Windows
# Usage: irm https://raw.githubusercontent.com/SlashpanOrg/agent-x/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "SlashpanOrg/agent-x"
$InstallDir = if ($env:AGENTX_INSTALL_DIR) { $env:AGENTX_INSTALL_DIR } else { "$env:LOCALAPPDATA\agentx" }
$BinDir = if ($env:AGENTX_BIN_DIR) { $env:AGENTX_BIN_DIR } else { "$env:LOCALAPPDATA\agentx\bin" }
$MinNodeVersion = 20

function Write-Info($msg) { Write-Host "  > $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }

# --- Platform detection ---

function Get-Platform {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($arch) {
        "X64" { return "win-x64" }
        "Arm64" { return "win-arm64" }
        default { Write-Err "Unsupported architecture: $arch" }
    }
}

# --- Prerequisites ---

function Test-NodeVersion {
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) {
        Write-Warn "Node.js not found. Attempting to install Node.js..."
        $choco = Get-Command choco -ErrorAction SilentlyContinue
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        $nodeInstalled = $false
        if ($choco) {
            Write-Info "Installing Node.js via Chocolatey..."
            choco install nodejs-lts -y
            $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
            if ($nodeCmd) { $nodeInstalled = $true }
        } elseif ($winget) {
            Write-Info "Installing Node.js via winget..."
            winget install OpenJS.NodeJS.LTS
            $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
            if ($nodeCmd) { $nodeInstalled = $true }
        }
        if (-not $nodeInstalled) {
            Write-Host "" -ForegroundColor Red
            Write-Err "Node.js could not be installed automatically. Please install Node.js >= $MinNodeVersion manually:"
            Write-Host "    choco install nodejs-lts" -ForegroundColor Cyan
            Write-Host "    winget install OpenJS.NodeJS.LTS" -ForegroundColor Cyan
            Write-Host "    Or download from: https://nodejs.org/en/download" -ForegroundColor Cyan
            exit 1
        }
    }
    $version = (node -v) -replace '^v', ''
    $major = [int]($version.Split('.')[0])
    if ($major -lt $MinNodeVersion) {
        Write-Err "Node.js $MinNodeVersion+ required (found v$version). Upgrade: https://nodejs.org"
    }
    Write-Ok "Node.js v$version"
}

# --- Version resolution ---

function Get-LatestVersion {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -ErrorAction Stop
    return $release.tag_name
}

# --- Clean existing ---

function Remove-Existing {
    if (Test-Path $InstallDir) {
        Write-Warn "Removing existing installation at $InstallDir"
        Remove-Item -Recurse -Force $InstallDir
        Write-Ok "Removed $InstallDir"
    }
}

# --- Installation mode selection ---

function Select-InstallMode {
    Write-Host ""
    Write-Host "  Installation mode:" -ForegroundColor Cyan
    Write-Host "    1) TUI only     — Terminal interface (lightweight)"
    Write-Host "    2) TUI + Web-UI — Terminal + browser interface"
    Write-Host ""

    $choice = Read-Host "  Select [1/2] (default: 2)"
    if ($choice -eq "1") {
        $script:INSTALL_MODE = "tui-only"
        Write-Host "  TUI-only mode selected." -ForegroundColor DarkGray
    } else {
        $script:INSTALL_MODE = "full"
        Write-Host "  Full mode selected (TUI + Web-UI)." -ForegroundColor DarkGray
    }
}

# --- Download and install ---

function Install-AgentX {
    $platform = Get-Platform
    $version = Get-LatestVersion
    Write-Ok "Version: $version"
    Write-Ok "Platform: $platform"

    $suffix = ""
    if ($script:INSTALL_MODE -eq "tui-only") {
        $suffix = "-tui"
    }
    $url = "https://github.com/$Repo/releases/download/$version/agentx-$platform$suffix.zip"
    $tmpFile = Join-Path $env:TEMP "agentx-$platform$suffix.zip"

    Write-Info "Downloading agentx-$platform$suffix.zip..."
    Invoke-WebRequest -Uri $url -OutFile $tmpFile -ErrorAction Stop

    Write-Info "Installing to $InstallDir..."
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Expand-Archive -Path $tmpFile -DestinationPath $InstallDir -Force
    Remove-Item $tmpFile -Force

    # Create bin directory with agentx.cmd
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
    $cmdContent = "@echo off`r`nnode `"$InstallDir\index.js`" %*"
    Set-Content -Path "$BinDir\agentx.cmd" -Value $cmdContent -Encoding ASCII

    Write-Ok "Installed to $InstallDir"
}

# --- PATH management ---

function Add-ToPath {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -split ";" | Where-Object { $_ -eq $BinDir }) {
        return
    }
    Write-Warn "$BinDir is not in your PATH"
    [Environment]::SetEnvironmentVariable("PATH", "$BinDir;$userPath", "User")
    $env:PATH = "$BinDir;$env:PATH"
    Write-Ok "Added $BinDir to user PATH."
    # Try to reload the environment for the current session
    $shell = (Get-Process -Id $PID).Path
    if ($shell -like "*powershell*") {
        Write-Host "  Reloading PATH for this session..." -ForegroundColor Cyan
        $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User")
        Write-Host "  If 'agentx' is still not found, restart your terminal or run: `n    `$env:PATH = [Environment]::GetEnvironmentVariable(\"PATH\", \"User\")" -ForegroundColor Yellow
    } else {
        Write-Host "  Please restart your terminal to use 'agentx', or run: `n    `$env:PATH = [Environment]::GetEnvironmentVariable(\"PATH\", \"User\")" -ForegroundColor Yellow
    }
}

# --- Verify ---

function Test-Installation {
    if ((Test-Path "$InstallDir\index.js") -and (Test-Path "$BinDir\agentx.cmd")) {
        Write-Ok "Installation verified"
    } else {
        Write-Err "Installation failed — files not found"
    }
}

# --- Install optional dependencies (Tesseract for OCR) ---

function Install-OptionalDeps {
    $tesseract = Get-Command tesseract -ErrorAction SilentlyContinue
    if ($tesseract) {
        Write-Ok "Tesseract OCR already installed"
        return
    }

    # Try choco or winget
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    $winget = Get-Command winget -ErrorAction SilentlyContinue

    if ($choco) {
        Write-Info "Installing Tesseract OCR via Chocolatey..."
        choco install tesseract -y 2>$null | Out-Null
        if ($?) { Write-Ok "Tesseract OCR installed"; return }
    }
    if ($winget) {
        Write-Info "Installing Tesseract OCR via winget..."
        winget install UB-Mannheim.TesseractOCR --silent 2>$null | Out-Null
        if ($?) { Write-Ok "Tesseract OCR installed"; return }
    }

    Write-Warn "Tesseract OCR not installed (needed for image text extraction)"
    Write-Host "    Install manually: choco install tesseract  OR  winget install UB-Mannheim.TesseractOCR" -ForegroundColor DarkGray
}

# --- Main ---

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║         Agent-X Installer             ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Test-NodeVersion
Write-Host ""

Select-InstallMode
Write-Host ""

Remove-Existing
Install-AgentX
Add-ToPath
Test-Installation
Install-OptionalDeps

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║   Agent-X installed successfully! 🚀  ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
if ($script:INSTALL_MODE -eq "tui-only") {
    Write-Host "  Installed:     TUI only" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Get started:   agentx"
} else {
    Write-Host "  Installed:     TUI + Web-UI" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Get started:   agentx"
    Write-Host "  Daemon:        agentx start"
}
Write-Host "  Help:          agentx --help"
Write-Host ""
