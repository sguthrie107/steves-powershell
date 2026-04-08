# ==============================================================================
# CS2-SHELL: The Empress & The Emperor
# Microsoft.PowerShell_profile.ps1 — v1.0
#
# Inspired by AK-47 | The Empress (dark/ornate) and M4A4 | The Emperor (royal/precise).
# Designed for Data & Cloud Engineering workflows on Windows with PowerShell 7+.
#
# USAGE (sandboxed test — no profile override required):
#   pwsh -NoProfile -NoExit -Command {
#       $RepoTheme = "$PSScriptRoot\Microsoft.PowerShell_profile.ps1"
#       if (Test-Path $RepoTheme) {
#           . $RepoTheme
#           Write-Host "--- CS2-Shell: Sandboxed Session Active ---" -ForegroundColor Cyan
#       } else {
#           Write-Error "Theme file not found in repo root."
#       }
#   }
#
# FULL INSTALL:  Run .\Install.ps1 from the repo root.
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SCRIPT ROOT DETECTION
#    Capture the repo root at parse-time so it is available in nested function
#    calls regardless of how the profile is loaded (direct, dot-sourced, etc.)
# ------------------------------------------------------------------------------
$CS2ShellRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $PWD.Path
}

# ==============================================================================
# SECTION 1: THEME SELECTION
# ------------------------------------------------------------------------------
# • Override at any time:  $env:CS2_THEME = "empress"  OR  Set-CS2Theme empress
# • Default schedule:      Day (07:00–18:59) → Emperor | Night → Empress
# ==============================================================================

function Get-CS2Theme {
    <#
    .SYNOPSIS
        Returns the active CS2-Shell theme name ("empress" or "emperor").
    #>
    if ($env:CS2_THEME -and ($env:CS2_THEME -in @("empress", "emperor"))) {
        return $env:CS2_THEME
    }
    $hour = (Get-Date).Hour
    if ($hour -ge 7 -and $hour -lt 19) { return "emperor" }
    return "empress"
}

function Set-CS2Theme {
    <#
    .SYNOPSIS
        Switches the active CS2-Shell theme and reloads the prompt.
    .EXAMPLE
        Set-CS2Theme empress
        Set-CS2Theme emperor
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("empress", "emperor")]
        [string]$Theme
    )
    $env:CS2_THEME = $Theme
    $themePath = Join-Path $CS2ShellRoot "themes\$Theme.omp.json"
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        if (Test-Path $themePath) {
            oh-my-posh init pwsh --config $themePath | Invoke-Expression
            Write-Host "CS2-Shell: Switched to '$Theme' theme." -ForegroundColor Cyan
        } else {
            Write-Warning "CS2-Shell: Theme file not found: $themePath"
        }
    } else {
        Write-Warning "CS2-Shell: oh-my-posh not installed. Run .\Install.ps1"
    }
}

# ==============================================================================
# SECTION 2: OH MY POSH INITIALIZATION
# ------------------------------------------------------------------------------
# Requires: oh-my-posh  (installed via Install.ps1 or winget)
# Requires: A Nerd Font (e.g. CaskaydiaCove Nerd Font or FiraCode Nerd Font)
# ==============================================================================

$_activeTheme    = Get-CS2Theme
$_activeThemePath = Join-Path $CS2ShellRoot "themes\$_activeTheme.omp.json"

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    if (Test-Path $_activeThemePath) {
        oh-my-posh init pwsh --config $_activeThemePath | Invoke-Expression
    } else {
        Write-Warning "CS2-Shell: Theme file missing at '$_activeThemePath'. Using OMP defaults."
        oh-my-posh init pwsh | Invoke-Expression
    }
} else {
    Write-Warning "CS2-Shell: oh-my-posh not found. Run '.\Install.ps1' to complete setup."

    # Fallback prompt: plain git-branch-aware prompt when OMP is unavailable
    function prompt {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        $location = $ExecutionContext.SessionState.Path.CurrentLocation
        $promptSuffix = if ($branch) { " [$branch]" } else { "" }
        $exitColor = if ($?) { "Green" } else { "Red" }
        Write-Host "PS " -NoNewline -ForegroundColor DarkGray
        Write-Host "$location" -NoNewline -ForegroundColor Cyan
        Write-Host "$promptSuffix" -NoNewline -ForegroundColor Yellow
        Write-Host " ❯" -NoNewline -ForegroundColor $exitColor
        return " "
    }
}

# ==============================================================================
# SECTION 3: MODULE IMPORTS
# ------------------------------------------------------------------------------
# Install-Module commands are in Install.ps1. Here we load silently if present.
# ==============================================================================

$_cs2Modules = @(
    "Terminal-Icons",   # File-type icons in Get-ChildItem / ls output
    "z"                 # Frecency-based directory jumping  (z <partial-path>)
)

foreach ($_mod in $_cs2Modules) {
    Import-Module $_mod -ErrorAction SilentlyContinue
}

Remove-Variable _cs2Modules, _activeTheme, _activeThemePath -ErrorAction SilentlyContinue

# ==============================================================================
# SECTION 4: PSREADLINE — UNIX / EMACS KEYBINDINGS
# ------------------------------------------------------------------------------
# PSReadLine comes with PowerShell 7+.  Setting EditMode to Emacs enables the
# core Unix bindings automatically.  Additional bindings are listed below.
# ==============================================================================

if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine

    # Core Emacs editing mode (enables Ctrl+A/E, Alt+F/B, Ctrl+R, etc.)
    Set-PSReadLineOption -EditMode Emacs

    # History behaviour
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -MaximumHistoryCount 10000
    Set-PSReadLineOption -HistoryNoDuplicates

    # Predictive IntelliSense (requires PSReadLine >= 2.1)
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView       -ErrorAction SilentlyContinue
    }

    # ── Unix key bindings (most covered by EditMode Emacs; extras below) ──────
    # Ctrl+D  — delete char forward, or exit shell when line is empty
    Set-PSReadLineKeyHandler -Key Ctrl+d          -Function DeleteCharOrExit
    # Ctrl+K  — kill (cut) from cursor to end of line
    Set-PSReadLineKeyHandler -Key Ctrl+k          -Function KillLine
    # Ctrl+U  — kill from cursor to beginning of line
    Set-PSReadLineKeyHandler -Key Ctrl+u          -Function BackwardKillLine
    # Ctrl+W  — kill previous word (whitespace-delimited, Unix style)
    Set-PSReadLineKeyHandler -Key Ctrl+w          -Function BackwardKillWord
    # Alt+D   — kill next word forward
    Set-PSReadLineKeyHandler -Key Alt+d           -Function KillWord
    # Alt+Bksp — kill previous word (alternative)
    Set-PSReadLineKeyHandler -Key Alt+Backspace   -Function BackwardKillWord
    # Ctrl+L  — clear screen (preserves current command line)
    Set-PSReadLineKeyHandler -Key Ctrl+l          -Function ClearScreen
    # Up/Down — search history matching current input prefix
    Set-PSReadLineKeyHandler -Key UpArrow         -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow       -Function HistorySearchForward
    # Tab     — menu-style completion (cycle with Tab/Shift+Tab)
    Set-PSReadLineKeyHandler -Key Tab             -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Shift+Tab       -Function Complete

    # ── Syntax highlighting colours (theme-aware) ────────────────────────────
    $activeTheme = Get-CS2Theme
    if ($activeTheme -eq "empress") {
        Set-PSReadLineOption -Colors @{
            Command            = "#FFEC2F"   # Gold
            Parameter          = "#9FBE8B"   # Sage Mint
            String             = "#00BFFF"   # Sky Blue
            Operator           = "#FFEC2F"   # Gold
            Variable           = "#9FBE8B"   # Sage Mint
            Comment            = "#555555"   # Dark grey
            Keyword            = "#B060FF"   # Soft violet
            Error              = "#5B0000"   # Blood Red
            InlinePrediction   = "#444477"
        }
    } else {
        Set-PSReadLineOption -Colors @{
            Command            = "#A58C62"   # Goldenrod
            Parameter          = "#CDD0CB"   # Silver Grey
            String             = "#00BFFF"   # Sky Blue
            Operator           = "#A58C62"   # Goldenrod
            Variable           = "#CDD0CB"   # Silver Grey
            Comment            = "#555555"   # Dark grey
            Keyword            = "#510E6F"   # Midnight Purple
            Error              = "#CC0000"   # Red
            InlinePrediction   = "#445577"
        }
    }
    Remove-Variable activeTheme -ErrorAction SilentlyContinue
}

# ==============================================================================
# SECTION 5: ALIASES & UNIX-LIKE COMMANDS
# ==============================================================================

# ── Directory listing ─────────────────────────────────────────────────────────
function ll {
    <#.SYNOPSIS Long-form ls: all files/dirs, human-readable, sorted by name.#>
    Get-ChildItem -Force @args | Format-Table Mode, LastWriteTime, Length, Name -AutoSize
}

function la {
    <#.SYNOPSIS List ALL items including hidden, with full attributes.#>
    Get-ChildItem -Force -Attributes Hidden, Normal, Directory @args |
        Format-Table Mode, LastWriteTime, Length, Name -AutoSize
}

# ── File operations ───────────────────────────────────────────────────────────
function touch {
    <#
    .SYNOPSIS
        Create an empty file, or update the LastWriteTime of an existing one.
    .EXAMPLE
        touch notes.txt
        touch a.txt b.txt
    #>
    param([Parameter(ValueFromRemainingArguments)][string[]]$Paths)
    foreach ($p in $Paths) {
        if (Test-Path $p) {
            (Get-Item $p).LastWriteTime = Get-Date
        } else {
            New-Item -ItemType File -Path $p -Force | Out-Null
        }
    }
}

function mkcd {
    <#
    .SYNOPSIS Create a directory and immediately cd into it.#>
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# ── Navigation shortcuts ──────────────────────────────────────────────────────
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# ── Process / command lookup ──────────────────────────────────────────────────
function which {
    <#.SYNOPSIS Show the resolved path of a command (like Unix which).#>
    param([Parameter(Mandatory)][string]$Command)
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if ($cmd) { $cmd.Source } else { Write-Warning "which: command not found: $Command" }
}

# ── Git helpers ───────────────────────────────────────────────────────────────
function Get-GitBranch {
    <#.SYNOPSIS Returns the current git branch name, or $null if not in a repo.#>
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0) { return $branch }
    return $null
}

function gs  { git status @args }
function gd  { git diff   @args }
function ga  { git add    @args }
function gc  { git commit @args }
function gp  { git push   @args }
function gl  { git log --oneline --graph --decorate @args }
function gco { git checkout @args }
function gb  { git branch   @args }

# ── Open in explorer / editor ─────────────────────────────────────────────────
Set-Alias -Name open   -Value Invoke-Item       -ErrorAction SilentlyContinue
Set-Alias -Name edit   -Value code              -ErrorAction SilentlyContinue  # VS Code

# ── Grep (pipe-friendly) ──────────────────────────────────────────────────────
Set-Alias -Name grep   -Value Select-String     -ErrorAction SilentlyContinue

# ── Reload profile ────────────────────────────────────────────────────────────
function reload {
    <#.SYNOPSIS Re-source the active PowerShell profile.#>
    . $PROFILE
    Write-Host "Profile reloaded." -ForegroundColor Green
}

# ==============================================================================
# SECTION 6: ENVIRONMENT & QUALITY-OF-LIFE
# ==============================================================================

# UTF-8 everywhere
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding            = [System.Text.Encoding]::UTF8

# Increase scroll-back / history
$Host.PrivateData.ErrorForegroundColor   = "Red"
$Host.PrivateData.WarningForegroundColor = "Yellow"

# Shorter default formatting for common types
$FormatEnumerationLimit = 10

# ==============================================================================
# SECTION 7: EXTENSIBILITY HOOK
# ------------------------------------------------------------------------------
# Add custom modules, completions, or environment setup below this line.
# This section is intentionally kept separate so you can modify it freely
# without touching the core CS2-Shell config above.
# ==============================================================================

# ── Example: Cloud SDK completions ───────────────────────────────────────────
# Import-Module Az                       -ErrorAction SilentlyContinue
# Import-Module AWSPowerShell.NetCore    -ErrorAction SilentlyContinue
# Import-Module GoogleCloud              -ErrorAction SilentlyContinue

# ── Example: Load a local .env file ──────────────────────────────────────────
# if (Test-Path "$PWD\.env") { Get-Content "$PWD\.env" | ForEach-Object {
#     if ($_ -match "^([^#][^=]*)=(.*)$") { [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process") }
# }}

# ── Example: Custom functions file ───────────────────────────────────────────
# $customFile = Join-Path $CS2ShellRoot "custom\my-functions.ps1"
# if (Test-Path $customFile) { . $customFile }
