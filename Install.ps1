#Requires -Version 7.0
# ==============================================================================
# CS2-SHELL: Install.ps1
# One-time setup script — run from the repo root:
#   cd C:\path\to\steves-powershell
#   .\Install.ps1
#
# What this script does:
#   1. Verifies prerequisites (PowerShell 7+, winget)
#   2. Installs Oh My Posh (prompt engine)
#   3. Installs required PowerShell modules (Terminal-Icons, z, PSReadLine)
#   4. Guides you through Nerd Font installation
#   5. Configures your $PROFILE to dot-source this repo's profile
# ==============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipFontPrompt,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

# ── Helper functions ──────────────────────────────────────────────────────────
function Write-Step  { param([string]$Msg) Write-Host "`n[$([char]0x2022)] $Msg" -ForegroundColor Cyan }
function Write-OK    { param([string]$Msg) Write-Host "  [OK]  $Msg" -ForegroundColor Green }
function Write-Skip  { param([string]$Msg) Write-Host "  [--]  $Msg" -ForegroundColor DarkGray }
function Write-Warn  { param([string]$Msg) Write-Host "  [!!]  $Msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$Msg) Write-Host "  [XX]  $Msg" -ForegroundColor Red }

# ── Banner ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor DarkYellow
Write-Host "  ║   CS2-Shell: The Empress & The Emperor           ║" -ForegroundColor DarkYellow
Write-Host "  ║   PowerShell Theme Environment — Installer v1.0  ║" -ForegroundColor DarkYellow
Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor DarkYellow
Write-Host ""

# ==============================================================================
# STEP 1: PREREQUISITES
# ==============================================================================
Write-Step "Checking prerequisites..."

# PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Fail "PowerShell 7+ is required. Current: $($PSVersionTable.PSVersion)"
    Write-Host "  Download from: https://aka.ms/powershell" -ForegroundColor Yellow
    exit 1
}
Write-OK "PowerShell $($PSVersionTable.PSVersion)"

# winget
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetCmd) {
    Write-Warn "winget not found. Oh My Posh must be installed manually."
    Write-Host "  Install: https://github.com/microsoft/winget-cli/releases" -ForegroundColor Yellow
    $skipOmp = $true
} else {
    Write-OK "winget found at: $($wingetCmd.Source)"
    $skipOmp = $false
}

# ==============================================================================
# STEP 2: OH MY POSH
# ==============================================================================
Write-Step "Installing Oh My Posh..."

$ompInstalled = Get-Command oh-my-posh -ErrorAction SilentlyContinue

if ($ompInstalled -and -not $Force) {
    Write-Skip "oh-my-posh already installed ($($ompInstalled.Source)). Use -Force to reinstall."
} elseif ($skipOmp) {
    Write-Warn "Skipping Oh My Posh install (winget unavailable). Install manually:"
    Write-Host "  https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Yellow
} else {
    Write-Host "  Running: winget install JanDeDobbeleer.OhMyPosh --accept-source-agreements --accept-package-agreements" -ForegroundColor DarkGray
    if ($PSCmdlet.ShouldProcess("Oh My Posh", "Install via winget")) {
        winget install JanDeDobbeleer.OhMyPosh --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            # Refresh PATH so oh-my-posh is available in this session
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("PATH", "User")
            Write-OK "Oh My Posh installed."
        } else {
            Write-Fail "winget install failed (exit code $LASTEXITCODE). Check the output above."
        }
    }
}

# ==============================================================================
# STEP 3: POWERSHELL MODULES
# ==============================================================================
Write-Step "Installing PowerShell modules..."

$modules = @(
    @{ Name = "PSReadLine";       MinVersion = "2.1.0"; Description = "Unix keybindings + IntelliSense" },
    @{ Name = "Terminal-Icons";   MinVersion = "0.9.0"; Description = "File-type icons in directory listings" },
    @{ Name = "z";                MinVersion = "1.1.3"; Description = "Frecency directory jumping (z <path>)" }
)

foreach ($mod in $modules) {
    $installed = Get-Module -ListAvailable -Name $mod.Name |
                    Where-Object { $_.Version -ge [version]$mod.MinVersion } |
                    Select-Object -First 1

    if ($installed -and -not $Force) {
        Write-Skip "$($mod.Name) $($installed.Version) already installed — $($mod.Description)"
    } else {
        Write-Host "  Installing $($mod.Name) >= $($mod.MinVersion) — $($mod.Description)" -ForegroundColor DarkGray
        if ($PSCmdlet.ShouldProcess($mod.Name, "Install-Module")) {
            try {
                Install-Module -Name $mod.Name -MinimumVersion $mod.MinVersion `
                    -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-OK "$($mod.Name) installed."
            } catch {
                Write-Warn "Could not install $($mod.Name): $_"
            }
        }
    }
}

# ==============================================================================
# STEP 4: NERD FONT GUIDANCE
# ==============================================================================
Write-Step "Nerd Font requirement..."

if (-not $SkipFontPrompt) {
    Write-Host @"

  CS2-Shell uses Nerd Font glyphs for the powerline arrows, git branch icon,
  and other symbols in the prompt. Without a Nerd Font the prompt will show
  placeholder boxes instead of the intended icons.

  Recommended fonts (free):
    • CascadiaCode Nerd Font   — https://github.com/ryanoasis/nerd-fonts/releases
    • FiraCode Nerd Font       — https://github.com/ryanoasis/nerd-fonts/releases
    • JetBrainsMono Nerd Font  — https://www.nerdfonts.com/font-downloads

  After installing a Nerd Font:
    • Windows Terminal  → Settings → Profile → Appearance → Font face
    • VS Code Terminal  → Settings → terminal.integrated.fontFamily

  Oh My Posh can also install CascadiaCode automatically:
    oh-my-posh font install CascadiaCode

"@ -ForegroundColor Yellow

    $confirm = Read-Host "  Open the Nerd Fonts download page now? [y/N]"
    if ($confirm -match "^y") {
        Start-Process "https://www.nerdfonts.com/font-downloads"
    }
} else {
    Write-Skip "Nerd Font prompt skipped (-SkipFontPrompt)."
}

# ==============================================================================
# STEP 5: CONFIGURE $PROFILE
# ==============================================================================
Write-Step "Configuring `$PROFILE..."

$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir  = Split-Path $profilePath -Parent
$sourceLine  = ". `"$RepoRoot\Microsoft.PowerShell_profile.ps1`""

# Create profile directory if it does not exist
if (-not (Test-Path $profileDir)) {
    if ($PSCmdlet.ShouldProcess($profileDir, "Create directory")) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
}

# Read existing profile content (or empty string)
$existingContent = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { "" }

if ($existingContent -match [regex]::Escape($RepoRoot)) {
    Write-Skip "`$PROFILE already references this repo. No changes made."
} else {
    $headerComment = "# CS2-Shell: auto-added by Install.ps1 — $(Get-Date -Format 'yyyy-MM-dd')"
    $addContent    = "`n$headerComment`n$sourceLine`n"

    if ($PSCmdlet.ShouldProcess($profilePath, "Append dot-source line")) {
        Add-Content -Path $profilePath -Value $addContent -Encoding UTF8
        Write-OK "Dot-source line added to: $profilePath"
    }
}

# ==============================================================================
# DONE
# ==============================================================================
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║   CS2-Shell installation complete!               ║" -ForegroundColor Green
Write-Host "  ║   Restart your terminal to activate the theme.   ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Quick-start commands:" -ForegroundColor Cyan
Write-Host "    Set-CS2Theme empress   # Switch to The Empress (dark/night)"   -ForegroundColor DarkGray
Write-Host "    Set-CS2Theme emperor   # Switch to The Emperor (day/clinical)" -ForegroundColor DarkGray
Write-Host "    ll                     # Long-form directory listing"           -ForegroundColor DarkGray
Write-Host "    z <partial-path>       # Jump to a frecently-visited directory" -ForegroundColor DarkGray
Write-Host "    gl                     # Pretty git log"                        -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Sandboxed test (no profile restart needed):" -ForegroundColor Cyan
Write-Host @"
    pwsh -NoProfile -NoExit -Command {
        . "$RepoRoot\Microsoft.PowerShell_profile.ps1"
        Write-Host '--- CS2-Shell: Sandboxed Session Active ---' -ForegroundColor Cyan
    }
"@ -ForegroundColor DarkGray
Write-Host ""
