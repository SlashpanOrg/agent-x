# Agent-X Installer for Windows — Ground Control Edition
# Usage: irm https://raw.githubusercontent.com/SlashpanOrg/agent-x/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "SlashpanOrg/agent-x"
$InstallDir = if ($env:AGENTX_INSTALL_DIR) { $env:AGENTX_INSTALL_DIR } else { "$env:LOCALAPPDATA\agentx" }
$BinDir = if ($env:AGENTX_BIN_DIR) { $env:AGENTX_BIN_DIR } else { "$env:LOCALAPPDATA\agentx\bin" }
$MinNodeVersion = 20

# ─── Colours ─────────────────────────────────────────────────────────

function Write-Ground($msg) { Write-Host "  $msg" -ForegroundColor DarkGray }
function Write-Info($msg) { Write-Host "  ⏳ $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }
function Write-Cmd($msg) { Write-Host "  $msg" -ForegroundColor DarkGray }

# ─── Mission phrases ─────────────────────────────────────────────────

$MissionPhrases = @(
  "Calibrating orbital insertion vectors",
  "Synchronising quantum entanglement buffers",
  "Establishing neural handshake protocol",
  "Deploying phased-array telemetry array",
  "Running pre-flight diagnostic suite",
  "Engaging inertial dampeners",
  "Aligning main reflector dish",
  "Warming up magnetron spindles",
  "Initialising subspace transceiver",
  "Performing cross-check on nav computers",
  "Boosting signal gain on deep-space network",
  "Running parity check on uplink channel",
  "Calculating Lagrange point insertion burn",
  "Spooling up reaction control wheels",
  "Synchronising atomic clock array",
  "Pinging relay satellite constellation",
  "Verifying encryption handshake keys",
  "Charging capacitor banks for main bus",
  "Unfurling solar panel arrays",
  "Loading mission parameters into flight computer",
  "Cross-referencing star charts with telemetry",
  "Running final go/no-go poll",
  "Priming thruster ignition sequence",
  "Acquiring lock on navigation beacon",
  "Stabilising attitude control system",
  "Verifying life support telemetry downlink",
  "Cycling coolant through primary loop",
  "Performing burn-time calculation",
  "Calibrating star tracker against known reference",
  "Checking pressure seals on payload bay",
  "Uploading waypoint sequence to autopilot",
  "Running loopback test on comms channel"
)

function Get-MissionPhrase {
  $idx = (Get-Date).Millisecond % $MissionPhrases.Count
  return $MissionPhrases[$idx]
}

# ─── Rocket ASCII ───────────────────────────────────────────────────

function Show-Rocket {
  Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor DarkGray
  Write-Host "  ║               A G E N T - X                  ║" -ForegroundColor Cyan
  Write-Host "  ║          WINDOWS GROUND CONTROL              ║" -ForegroundColor DarkGray
  Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "           .  .  .  .  .  .  .  ." -ForegroundColor DarkGray
  Write-Host "       .  .  .  .  .  .  .  .  .  ." -ForegroundColor DarkGray
  Write-Host "     .  .  .  .  .  .  .  .  .  .  ." -ForegroundColor DarkGray
  Write-Host "   .  .  .  .  ╔═══╗  .  .  .  .  ." -ForegroundColor DarkGray
  Write-Host "  .  .  .  .  ║ A ║  .  .  .  .  ." -ForegroundColor DarkGray
  Write-Host "  .  .  .  .  ╚═══╝  .  .  .  .  ." -ForegroundColor DarkGray
  Write-Host "   .  .  .  .  . ██ .  .  .  .  ." -ForegroundColor DarkGray
  Write-Host "     .  .  .  .  ██ .  .  .  ." -ForegroundColor DarkGray
  Write-Host "       .  .  .  /██\  .  .  ." -ForegroundColor DarkGray
  Write-Host "         .  . /  ██  \  .  ." -ForegroundColor DarkGray
  Write-Host "           . /   ██   \  ." -ForegroundColor DarkGray
  Write-Host "            /    ██    \" -ForegroundColor DarkGray
  Write-Host "           /  ~  ██  ~  \" -ForegroundColor DarkGray
  Write-Host "          /  ~ ~ ██ ~ ~  \" -ForegroundColor DarkGray
  Write-Host "         /  ~ ~ ~██~ ~ ~  \" -ForegroundColor DarkGray
  Write-Host "        /                \" -ForegroundColor DarkGray
  Write-Host "       /                  \" -ForegroundColor DarkGray
  Write-Host "      /   AGENT-X READY   \" -ForegroundColor Cyan
  Write-Host "     /____________________\" -ForegroundColor DarkGray
  Write-Host ""
}

# ─── Countdown ──────────────────────────────────────────────────────

function Show-Countdown {
  Write-Host ""
  Write-Host "  T-minus:" -ForegroundColor Cyan
  3..1 | ForEach-Object {
    Write-Host "    $_ seconds to deployment..." -NoNewline -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
    Write-Host "`r" -NoNewline
  }
  Write-Host "  ** LAUNCH **  All systems nominal." -ForegroundColor Green
  Start-Sleep -Milliseconds 500
}

# ─── Platform detection ─────────────────────────────────────────────

function Get-Platform {
  $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
  switch ($arch) {
    "X64" { return "win-x64" }
    "Arm64" { return "win-arm64" }
    default { Write-Err "Unsupported architecture: $arch" }
  }
}

# ─── Prerequisites ──────────────────────────────────────────────────

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
      Write-Err "Node.js could not be installed automatically. Please install Node.js >= $MinNodeVersion manually:"
      Write-Host "    choco install nodejs-lts" -ForegroundColor Cyan
      Write-Host "    winget install OpenJS.NodeJS.LTS" -ForegroundColor Cyan
      Write-Host "    Or download from: https://nodejs.org/en/download" -ForegroundColor Cyan
    }
  }
  $version = (node -v) -replace '^v', ''
  $major = [int]($version.Split('.')[0])
  if ($major -lt $MinNodeVersion) {
    Write-Err "Node.js $MinNodeVersion+ required (found v$version). Upgrade: https://nodejs.org"
  }
  Write-Ok "Node.js v$version"
}

# ─── Version resolution ─────────────────────────────────────────────

function Get-LatestVersion {
  Write-Progress -Activity "Resolving latest release tag from GitHub..." -Status "downlinking" -PercentComplete -1
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -ErrorAction Stop
  Write-Progress -Activity "Resolving latest release tag from GitHub..." -Completed
  return $release.tag_name
}

# ─── Clean existing ─────────────────────────────────────────────────

function Remove-Existing {
  if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
  }
}

# ─── Installation mode selection ────────────────────────────────────

function Select-InstallMode {
  Write-Host ""
  Write-Host "  DEPLOYMENT CONFIGURATION" -ForegroundColor Cyan
  Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
  Write-Host "  1) TUI only     - Terminal interface (lightweight)" -ForegroundColor Cyan
  Write-Host "  2) TUI + Web-UI - Terminal + browser interface" -ForegroundColor Cyan
  Write-Host ""

  $choice = ""
  if ($env:AGENTX_INSTALL_MODE) {
    $choice = $env:AGENTX_INSTALL_MODE
  } elseif ($Host.UI.RawUI) {
    $choice = Read-Host "  Select payload configuration [1/2] (default: 2)"
  }

  if ($choice -eq "1") {
    $script:INSTALL_MODE = "tui-only"
    Write-Host "  Payload: TUI-only (lightweight)" -ForegroundColor DarkGray
  } else {
    $script:INSTALL_MODE = "full"
    Write-Host "  Payload: TUI + Web-UI (full deployment)" -ForegroundColor DarkGray
  }
}

# ─── Download ───────────────────────────────────────────────────────

function Install-AgentX {
  $platform = Get-Platform
  $version = Get-LatestVersion
  Write-Ok "Latest release: $version"
  Write-Ground "Telemetry: $platform | Node $(node -v) | $version"

  $suffix = ""
  if ($script:INSTALL_MODE -eq "tui-only") {
    $suffix = "-tui"
  }
  $url = "https://github.com/$Repo/releases/download/$version/agentx-$platform$suffix.zip"
  $tmpFile = Join-Path $env:TEMP "agentx-$platform$suffix.zip"
  $dlPath = "$InstallDir\agentx-$platform$suffix.zip"

  Write-Cmd "Downlinking from: $url"

  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

  $progress = 0
  $phrase = Get-MissionPhrase
  try {
    Invoke-WebRequest -Uri $url -OutFile $tmpFile -ErrorAction Stop `
      -UseBasicParsing `
      -PassThru `
      | ForEach-Object {
        $response = $_
        if ($response.ContentLength -gt 0) {
          $reader = New-Object System.IO.FileStream $tmpFile, 'Open', 'Read'
          $totalBytes = $response.ContentLength
          $readBytes = 0
          $buffer = New-Object byte[] 8192
          while (($bytesRead = $reader.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $readBytes += $bytesRead
            $percent = [int](($readBytes / $totalBytes) * 100)
            Write-Progress -Activity "Downlinking payload..." -Status "$(Get-MissionPhrase)" -PercentComplete $percent
          }
          $reader.Close()
        } else {
          Invoke-WebRequest -Uri $url -OutFile $tmpFile -UseBasicParsing
        }
      }
  } catch {
    Write-Err "Download failed. Check your internet connection."
  }
  Write-Progress -Activity "Downlinking payload..." -Completed

  Write-Cmd "Unpacking payload..."
  Expand-Archive -Path $tmpFile -DestinationPath $InstallDir -Force
  Remove-Item $tmpFile -Force

  New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
  $cmdContent = "@echo off`r`nnode `"$InstallDir\index.js`" %*"
  Set-Content -Path "$BinDir\agentx.cmd" -Value $cmdContent -Encoding ASCII

  Write-Ok "Payload extracted to $InstallDir"
}

# ─── PATH management ────────────────────────────────────────────────

function Add-ToPath {
  $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  if ($userPath -split ";" | Where-Object { $_ -eq $BinDir }) {
    return
  }
  Write-Warn "$BinDir is not in your PATH"
  [Environment]::SetEnvironmentVariable("PATH", "$BinDir;$userPath", "User")
  $env:PATH = "$BinDir;$env:PATH"
  Write-Ok "Navigation beacon added to PATH"
  $shell = (Get-Process -Id $PID).Path
  if ($shell -like "*powershell*") {
    Write-Host "  Reloading navigation charts for this session..." -ForegroundColor Cyan
    $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Host "  If 'agentx' is still not found, restart your terminal or run: `n    `$env:PATH = [Environment]::GetEnvironmentVariable(\"PATH\", \"User\")" -ForegroundColor Yellow
  } else {
    Write-Host "  Please restart your terminal to use 'agentx', or run: `n    `$env:PATH = [Environment]::GetEnvironmentVariable(\"PATH\", \"User\")" -ForegroundColor Yellow
  }
}

# ─── Verify ─────────────────────────────────────────────────────────

function Test-Installation {
  if ((Test-Path "$InstallDir\index.js") -and (Test-Path "$BinDir\agentx.cmd")) {
    Write-Ok "Payload integrity verified"
  } else {
    Write-Err "Installation failed - payload integrity check failed"
  }
}

# ─── Install optional dependencies (Tesseract for OCR) ──────────────

function Install-OptionalDeps {
  $tesseract = Get-Command tesseract -ErrorAction SilentlyContinue
  if ($tesseract) {
    return
  }

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

# ─── Animated step runner ───────────────────────────────────────────

function Run-Step($msg, [ScriptBlock]$block) {
  Write-Progress -Activity $msg -Status "$(Get-MissionPhrase)" -PercentComplete -1
  try {
    & $block
    Write-Progress -Activity $msg -Completed
    Write-Ok $msg
  } catch {
    Write-Progress -Activity $msg -Completed
    Write-Err "$msg failed: $_"
  }
}

# ─── Main ───────────────────────────────────────────────────────────

Clear-Host
Show-Rocket
Write-Host "  PRE-LAUNCH SEQUENCE" -ForegroundColor DarkGray
Write-Host ""

Run-Step "Running pre-flight diagnostics" {
  Test-NodeVersion
}

Select-InstallMode
Show-Countdown

Run-Step "Clearing previous installation artifacts" {
  Remove-Existing
}

Install-AgentX

Run-Step "Locking navigation coordinates" {
  Add-ToPath
}

Run-Step "Running payload integrity check" {
  Test-Installation
}

Run-Step "Installing auxiliary sensors (OCR)" {
  Install-OptionalDeps
}

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║                                               ║" -ForegroundColor Green
Write-Host "  ║       **  DEPLOYMENT COMPLETE  **             ║" -ForegroundColor Green
Write-Host "  ║       Agent-X is now operational.             ║" -ForegroundColor Green
Write-Host "  ║                                               ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
if ($script:INSTALL_MODE -eq "tui-only") {
  Write-Host "  Payload:     TUI only" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Engage:      agentx"
} else {
  Write-Host "  Payload:     TUI + Web-UI" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Engage:      agentx"
  Write-Host "  Daemon:      agentx start"
}
Write-Host "  Help:        agentx --help"
Write-Host ""
