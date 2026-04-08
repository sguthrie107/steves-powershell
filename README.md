# CS2-Shell: The Empress & The Emperor

> A custom PowerShell environment and theme engine inspired by the iconic  
> **Counter-Strike 2** skins: **AK-47 | The Empress** and **M4A4 | The Emperor**.  
> Transforms the terminal into a highly functional, context-aware development  
> environment tailored for Data and Cloud Engineering.

---

## 🎨 Theme Specifications

CS2-Shell automatically selects a theme based on the time of day:

| Time of day | Active theme |
|---|---|
| 07:00 – 18:59 | **M4A4 \| The Emperor** (royal, clinical, precise) |
| 19:00 – 06:59 | **AK-47 \| The Empress** (ornate, powerful, dark) |

Override at any time with `Set-CS2Theme empress` or `Set-CS2Theme emperor`.

---

### AK-47 | The Empress

> *Ornate, powerful, dark.*

| Role | Colour | Hex |
|---|---|---|
| Background / segment fill | Primary Navy | `#000E7A` |
| Text / highlights | Accent Gold | `#FFEC2F` |
| Error states / dirty-git indicator | Blood Red | `#5B0000` |
| Path / success | Sage Mint | `#9FBE8B` |

---

### M4A4 | The Emperor

> *Royal, clinical, precise.*

| Role | Colour | Hex |
|---|---|---|
| Main segment | Royal Blue | `#005DFB` |
| Text accents / branch | Goldenrod | `#A58C62` |
| Sub-segments / path fill | Midnight Purple | `#510E6F` |
| Secondary info | Silver Grey | `#CDD0CB` |

---

## 🚀 Installation

### Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Windows | 10 / 11 | Tested on both |
| PowerShell | 7.2 + | [Download](https://aka.ms/powershell) |
| winget | any | Ships with Windows 10 21H2+ |
| Nerd Font | any | Required for prompt glyphs (see below) |

### 1 – Clone the repo

```powershell
git clone https://github.com/sguthrie107/steves-powershell.git
cd steves-powershell
```

### 2 – Run the installer

```powershell
.\Install.ps1
```

The installer will:

1. Verify PowerShell 7+ and winget are present
2. Install **Oh My Posh** via `winget install JanDeDobbeleer.OhMyPosh`
3. Install **PSReadLine** (2.1+), **Terminal-Icons**, and **z** from PSGallery
4. Guide you through selecting a **Nerd Font**
5. Append a single dot-source line to your `$PROFILE` so future sessions pick
   up the theme automatically

> **Tip:** Pass `-WhatIf` to preview changes without applying them.

### 3 – Install a Nerd Font

Oh My Posh requires a Nerd Font for the powerline arrows and git icons.  
The recommended option is **CascadiaCode Nerd Font** (ligatures + icons):

```powershell
oh-my-posh font install CascadiaCode
```

Then set it in your terminal:

- **Windows Terminal** → Settings → Profile → Appearance → Font face
- **VS Code** → Settings → `terminal.integrated.fontFamily`

### 4 – Restart your terminal

Open a fresh PowerShell 7 session and you should see the CS2-Shell prompt.

---

## 🧪 Sandboxed ("Localhost") Testing

Test changes to the theme **without** overwriting your real `$PROFILE` or  
restarting your terminal. Run from the repo root:

```powershell
pwsh -NoProfile -NoExit -Command {
    $RepoTheme = "$PSScriptRoot\Microsoft.PowerShell_profile.ps1"
    if (Test-Path $RepoTheme) {
        . $RepoTheme
        Write-Host "--- CS2-Shell: Sandboxed Session Active ---" -ForegroundColor Cyan
    } else {
        Write-Error "Theme file not found in repo root."
    }
}
```

---

## ⌨️ Unix / macOS Keybindings

PSReadLine is configured in **Emacs mode**, which gives you the same muscle  
memory as working on a Mac:

| Keybinding | Action |
|---|---|
| `Ctrl + A` | Move to beginning of line |
| `Ctrl + E` | Move to end of line |
| `Ctrl + K` | Cut from cursor to end of line |
| `Ctrl + U` | Cut from cursor to beginning of line |
| `Ctrl + W` | Cut previous word |
| `Alt + D` | Cut next word |
| `Alt + B` | Move back one word |
| `Alt + F` | Move forward one word |
| `Ctrl + R` | Reverse search history |
| `Ctrl + P` | Previous command in history |
| `Ctrl + N` | Next command in history |
| `Ctrl + D` | Delete char forward (or exit shell) |
| `Ctrl + L` | Clear screen |
| `Tab` | Menu-style autocomplete |
| `Shift + Tab` | Autocomplete previous suggestion |
| `↑ / ↓` | Search history matching current input |

---

## 🔧 Aliases & Functions

| Command | Equivalent / Description |
|---|---|
| `ll` | `Get-ChildItem -Force` (formatted table) |
| `la` | `Get-ChildItem` including hidden files |
| `touch <file>` | Create file or update modification time |
| `mkcd <dir>` | `mkdir` + `cd` in one step |
| `which <cmd>` | Show resolved path of a command |
| `open <path>` | `Invoke-Item` (open with default app) |
| `edit <file>` | Open in VS Code |
| `grep` | Alias for `Select-String` |
| `reload` | Re-source `$PROFILE` |
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `z <partial>` | Jump to a frecently-visited directory |
| `gs` | `git status` |
| `gd` | `git diff` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git log --oneline --graph --decorate` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `Set-CS2Theme <name>` | Switch theme: `empress` or `emperor` |
| `Get-GitBranch` | Returns current git branch name |

---

## 🗂️ Repository Structure

```
steves-powershell/
├── Microsoft.PowerShell_profile.ps1   # Main profile (dot-source this)
├── Install.ps1                         # One-time setup script
├── themes/
│   ├── empress.omp.json               # AK-47 | The Empress (Oh My Posh)
│   └── emperor.omp.json               # M4A4 | The Emperor (Oh My Posh)
└── README.md
```

---

## ➕ Adding Custom Modules & Settings

**Section 7** at the bottom of `Microsoft.PowerShell_profile.ps1` is your  
extensibility hook. Add anything there—cloud SDK completions, `.env` loaders,  
company-specific functions—without touching the core CS2-Shell config:

```powershell
# SECTION 7: EXTENSIBILITY HOOK
# ──────────────────────────────
Import-Module Az                       -ErrorAction SilentlyContinue
Import-Module AWSPowerShell.NetCore    -ErrorAction SilentlyContinue

# Load a local .env file into the current session
if (Test-Path "$PWD\.env") {
    Get-Content "$PWD\.env" | ForEach-Object {
        if ($_ -match "^([^#][^=]*)=(.*)$") {
            [System.Environment]::SetEnvironmentVariable(
                $Matches[1].Trim(), $Matches[2].Trim(), "Process"
            )
        }
    }
}
```

---

## 🔄 Updating

```powershell
cd C:\path\to\steves-powershell
git pull
# Restart your terminal — no re-installation required.
```

---

## 🙏 Dependencies

| Package | Purpose | License |
|---|---|---|
| [Oh My Posh](https://ohmyposh.dev) | Prompt engine | MIT |
| [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) | File-type icons | MIT |
| [PSReadLine](https://github.com/PowerShell/PSReadLine) | Keybindings + IntelliSense | BSD-2 |
| [z](https://github.com/badmotorfinger/z) | Directory jumping | MIT |

---

*CS2-Shell is an independent fan project and is not affiliated with Valve Corporation or Counter-Strike.*