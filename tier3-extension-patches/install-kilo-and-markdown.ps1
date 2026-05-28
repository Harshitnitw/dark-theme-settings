# Kilo Code + Markdown Preview Low Contrast Theme Installer
# Injects CSS into webview HTML templates for low-contrast text (#969696)
#
# Usage:
#   .\apply-low-contrast.ps1                    # Auto-detect
#   .\apply-low-contrast.ps1 -Path "C:\path\to\ext"  # Specify path
#
# Supports: Antigravity, VS Code, VSCodium, Cursor, Windsurf

param([string]$Path = "")

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupSuffix = ".bak." + (Get-Date -Format "yyyyMMddHHmmss")
$CssRule = "body,body *{color:#969696!important}"

# ============================================================
# 1. KILO CODE EXTENSION FIX
# ============================================================
function Patch-KiloExtension {
    param([string]$ExtDir)
    $JsFile = Join-Path $ExtDir "dist\extension.js"

    if (-not (Test-Path $JsFile)) {
        Write-Host "[WARN] Kilo Code extension.js not found: $JsFile" -ForegroundColor Yellow
        return 1
    }

    $Content = Get-Content $JsFile -Raw
    if ($Content -match [regex]::Escape($CssRule)) {
        Write-Host "[INFO] Kilo Code already patched" -ForegroundColor Cyan
        return 2
    }

    $BackupPath = $JsFile + $BackupSuffix
    Copy-Item $JsFile $BackupPath
    Write-Host "[INFO] Backed up: $BackupPath" -ForegroundColor Green

    $NewContent = $Content -replace '(\s{2}</style>)', "$CssRule`n`$1"
    Set-Content -Path $JsFile -Value $NewContent -NoNewline
    Write-Host "[INFO] Patched Kilo Code extension.js" -ForegroundColor Green
    return 0
}

# ============================================================
# 2. MARKDOWN PREVIEW FIX
# ============================================================
function Patch-MarkdownPreview {
    param([string]$BaseDir)
    $CssFile = Join-Path $BaseDir "extensions\markdown-language-features\media\markdown.css"

    if (-not (Test-Path $CssFile)) {
        Write-Host "[WARN] Markdown CSS not found: $CssFile" -ForegroundColor Yellow
        return 1
    }

    $Content = Get-Content $CssFile -Raw
    if ($Content -match "Low Contrast Text Overrides") {
        Write-Host "[INFO] Markdown preview already patched" -ForegroundColor Cyan
        return 2
    }

    $BackupPath = $CssFile + $BackupSuffix
    Copy-Item $CssFile $BackupPath
    Write-Host "[INFO] Backed up: $BackupPath" -ForegroundColor Green

    Add-Content -Path $CssFile -Value "`n/* Low Contrast Text Overrides */`n$CssRule`n" -NoNewline
    Write-Host "[INFO] Patched markdown preview CSS" -ForegroundColor Green
    return 0
}

# ============================================================
# FIND EXTENSIONS
# ============================================================
function Find-KiloExtension {
    param([string]$SearchPath)
    foreach ($Pattern in "kilocode.kilo-code-*", "kilocode.kilo-code", "kilo-code-*") {
        $Result = Get-ChildItem -Path $SearchPath -Directory -Filter $Pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Result) { return $Result.FullName }
    }
    return $null
}

$SearchPaths = @(
    "$env:USERPROFILE\.antigravity\extensions",
    "$env:USERPROFILE\.vscode\extensions",
    "$env:USERPROFILE\.vscode-oss\extensions",
    "$env:LOCALAPPDATA\Programs\Antigravity\resources\app\extensions",
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\resources\app\extensions"
)

Write-Host "============================================"
Write-Host " Low Contrast Theme Installer" -ForegroundColor Green
Write-Host " Text color: #969696 (dim gray)"
Write-Host "============================================"
Write-Host ""

$KiloDir = ""
$MarkdownBase = ""

if ($Path -ne "") {
    $KiloDir = $Path
    if (-not (Test-Path $KiloDir)) { Write-Host "[ERROR] Not found: $KiloDir" -ForegroundColor Red; exit 1 }
} else {
    foreach ($sp in $SearchPaths) {
        if (Test-Path $sp) {
            $KiloDir = Find-KiloExtension -SearchPath $sp
            if ($KiloDir) { break }
        }
    }
}

if (-not $KiloDir) {
    Write-Host "[ERROR] Could not find Kilo Code extension." -ForegroundColor Red
    Write-Host "  Usage: .\apply-low-contrast.ps1 -Path `"C:\path\to\kilocode.kilo-code-VERSION`""
    exit 1
}

Write-Host "[INFO] Kilo Code extension: $KiloDir" -ForegroundColor Green
Write-Host ""

$KiloResult = Patch-KiloExtension -ExtDir $KiloDir

if ($KiloResult -eq 0 -or $KiloResult -eq 2) {
    Write-Host ""
    Write-Host "============================================"
    Write-Host " Results:" -ForegroundColor Green
    if ($KiloResult -eq 0) { Write-Host "  Kilo Code:    patched" }
    if ($KiloResult -eq 2) { Write-Host "  Kilo Code:    already patched" }
    Write-Host "============================================"
    Write-Host ""
    Write-Host "Restart your editor completely (not just reload window)."
    Write-Host "Backups saved with suffix: $BackupSuffix"
}
