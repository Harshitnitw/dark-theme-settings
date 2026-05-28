#!/usr/bin/env bash
# Kilo Code + Markdown Preview Low Contrast Theme Installer
# Injects CSS into webview HTML templates for low-contrast text (#969696) + black backgrounds
#
# Usage:
#   sudo bash apply-low-contrast.sh             # Auto-detect (needs sudo for system dirs)
#   sudo bash apply-low-contrast.sh /path/to/ext # Specify path
#
# Supports: Antigravity, VS Code, VSCodium, Cursor, Windsurf

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# CSS rules. Critical design choice: we DO NOT use `body, body *` because
# that strips syntax-highlight colors in code blocks and diff colors in
# Kilo Code. Instead we set:
#   - body color/bg     -> dim gray on black (text descendants inherit)
#   - h1..h6, strong, b -> dimmer than body (anti-halation, opposite of usual)
#   - inline code       -> dim color + dim bg (no syntax hl on inline code anyway)
#   - pre/pre code      -> background only; foreground left to syntax highlighter
#
# This way: prose is dim gray, but code keeps its keywords/strings/types colored,
# and Kilo Code's diff red/green tints survive (just dimmed via bg-* utilities).
CSS_RULE='body{color:#969696!important;background-color:#000000!important}h1,h2,h3,h4,h5,h6,strong,b{color:#8a8a8a!important;font-weight:500!important}h1,h2{color:#7a7a7a!important}:not(pre)>code{color:#8a8a8a!important;background-color:#0a0a0a!important}pre{background-color:#020202!important}.bg-green-500,.bg-green-600{background-color:#0a150a!important}.bg-red-500,.bg-red-600{background-color:#150a0a!important}'
MD_CSS_RULE='body { color: #969696 !important; background-color: #000000 !important; }
h1, h2, h3, h4, h5, h6, strong, b { color: #8a8a8a !important; font-weight: 500 !important; }
h1, h2 { color: #7a7a7a !important; }
a { color: #5c758a !important; }
blockquote { color: #8a8a8a !important; border-left-color: #333 !important; background-color: #050505 !important; }
hr { border-color: #333 !important; }
table { border-color: #1a1a1a !important; }
table th { color: #8a8a8a !important; background-color: #050505 !important; }
table td { color: #969696 !important; background-color: #000000 !important; }
/* Inline code: dim — no syntax highlighting applies anyway */
:not(pre) > code { color: #8a8a8a !important; background-color: #0a0a0a !important; border: 1px solid #151515 !important; padding: 1px 4px !important; }
/* Fenced code blocks: only set background; let the syntax highlighter own the foreground */
pre { background-color: #020202 !important; border: 1px solid #0a0a0a !important; }
pre code { background-color: transparent !important; }'

# ============================================================
# 1. KILO CODE EXTENSION FIX
# Injects CSS into the webview HTML template in extension.js
# ============================================================
patch_kilo_extension() {
    local ext_dir="$1"
    local js_file="$ext_dir/dist/extension.js"

    if [ ! -f "$js_file" ]; then
        log_warn "Kilo Code extension.js not found: $js_file"
        return 1
    fi

    if grep -q "background-color:#000000!important" "$js_file" 2>/dev/null; then
        log_info "Kilo Code already patched"
        return 2
    fi

    cp "$js_file" "${js_file}${BACKUP_SUFFIX}"
    log_info "Backed up: ${js_file}${BACKUP_SUFFIX}"

    # Inject CSS before </style> in the webview HTML template
    perl -i -0pe "s/(  <\/style>)/${CSS_RULE}\n\$1/" "$js_file"
    log_info "Patched Kilo Code extension.js"
    return 0
}

# ============================================================
# 2. MARKDOWN PREVIEW FIX
# Appends CSS to markdown.css (system directory, needs sudo)
# ============================================================
patch_markdown_preview() {
    local base_dir="$1"
    local css_file="$base_dir/extensions/markdown-language-features/media/markdown.css"

    if [ ! -f "$css_file" ]; then
        log_warn "Markdown CSS not found: $css_file"
        return 1
    fi

    if grep -q "Low Contrast Text Overrides" "$css_file" 2>/dev/null; then
        log_info "Markdown preview already patched"
        return 2
    fi

    cp "$css_file" "${css_file}${BACKUP_SUFFIX}"
    log_info "Backed up: ${css_file}${BACKUP_SUFFIX}"

    printf '\n/* Low Contrast Text Overrides */\n%s\n' "$MD_CSS_RULE" >> "$css_file"
    log_info "Patched markdown preview CSS"
    return 0
}

# ============================================================
# 3. ANTIGRAVITY WORKBENCH CSS + HTML LINK
# Copies our pre-built antigravity-custom.css into the workbench
# directory and ensures workbench.html + workbench-jetski-agent.html
# both <link> to it. The CSS is sourced from this repo so the
# definitive copy lives in source control, not on the live system.
# ============================================================
patch_antigravity_workbench() {
    local base_dir="$1"
    local wb_dir="$base_dir/out/vs/code/electron-browser/workbench"
    local css_file="$wb_dir/antigravity-custom.css"
    local source_css="$SCRIPT_DIR/../antigravity dark theme/antigravity-custom.css"

    if [ ! -d "$wb_dir" ]; then
        log_warn "Antigravity workbench dir not found: $wb_dir"
        return 1
    fi

    if [ ! -f "$source_css" ]; then
        log_warn "Source CSS not found: $source_css"
        return 1
    fi

    # Backup existing live CSS if present
    [ -f "$css_file" ] && cp "$css_file" "${css_file}${BACKUP_SUFFIX}"

    # Install the canonical CSS
    cp "$source_css" "$css_file"
    log_info "Installed antigravity-custom.css"

    # Inject <link> into each workbench HTML if missing
    for html in "$wb_dir/workbench.html" "$wb_dir/workbench-jetski-agent.html"; do
        [ ! -f "$html" ] && continue
        if grep -q "antigravity-custom.css" "$html"; then
            log_info "$(basename "$html"): already linked"
        else
            cp "$html" "${html}${BACKUP_SUFFIX}"
            # Insert link right after the last existing <link rel="stylesheet" ...> line
            awk '
                /<link rel="stylesheet"/ { last=NR; lines[NR]=$0; next }
                { lines[NR]=$0 }
                END {
                    for (i=1; i<=NR; i++) {
                        print lines[i]
                        if (i==last) print "\t<!-- Anti-halation custom overrides -->\n\t<link rel=\"stylesheet\" href=\"./antigravity-custom.css\">"
                    }
                }
            ' "$html" > "${html}.new" && mv "${html}.new" "$html"
            log_info "$(basename "$html"): link injected"
        fi
    done

    return 0
}

# ============================================================
# FIND EXTENSION DIRECTORIES
# ============================================================
find_kilo_extension() {
    local search_path="$1"
    for pattern in "kilocode.kilo-code-*" "kilocode.kilo-code" "kilo-code-*"; do
        local result
        result=$(find "$search_path" -maxdepth 1 -type d -name "$pattern" 2>/dev/null | head -1)
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
    done
    return 1
}

# Resolve the user's home — under `sudo` $HOME is /root, so prefer
# $SUDO_USER's home when present so we still find ~/.antigravity etc.
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME="$HOME"
fi

# Search paths (user + system)
SEARCH_PATHS=(
    "$USER_HOME/.antigravity/extensions"
    "$USER_HOME/.vscode/extensions"
    "$USER_HOME/.vscode-oss/extensions"
    "$USER_HOME/.cursor/extensions"
    "$USER_HOME/.windsurf/extensions"
    "/usr/share/antigravity/resources/app/extensions"
    "/usr/share/code/resources/app/extensions"
    "/usr/share/vscodium/resources/app/extensions"
)

# ============================================================
# MAIN
# ============================================================
echo "============================================"
echo " Low Contrast Theme Installer"
echo " Text color: #969696 (dim gray)"
echo " Backgrounds: #000000 (pure black)"
echo "============================================"
echo ""

KILO_DIR=""
MARKDOWN_BASE=""
ANTIGRAVITY_BASE=""

if [ -n "$1" ]; then
    KILO_DIR="$1"
    [ ! -d "$KILO_DIR" ] && { log_error "Directory not found: $KILO_DIR"; exit 1; }
fi

# Always search for KILO_DIR if not given
if [ -z "$KILO_DIR" ]; then
    for search_path in "${SEARCH_PATHS[@]}"; do
        [ ! -d "$search_path" ] && continue
        KILO_DIR=$(find_kilo_extension "$search_path") && break
    done
fi

# Markdown extension lives in the system app dir, NOT the user extensions dir.
# (It's a built-in extension bundled with the IDE.) Search system paths.
SYSTEM_APP_PATHS=(
    "/usr/share/antigravity/resources/app"
    "/usr/share/code/resources/app"
    "/usr/share/vscodium/resources/app"
    "/opt/Antigravity/resources/app"
    "/Applications/Antigravity.app/Contents/Resources/app"
    "/Applications/Visual Studio Code.app/Contents/Resources/app"
)
for app_path in "${SYSTEM_APP_PATHS[@]}"; do
    if [ -d "$app_path/extensions/markdown-language-features" ]; then
        MARKDOWN_BASE="$app_path"
        break
    fi
done

# Antigravity base: same family of system paths
for app_path in "${SYSTEM_APP_PATHS[@]}"; do
    if [ -d "$app_path/out/vs/code/electron-browser/workbench" ]; then
        ANTIGRAVITY_BASE="$app_path"
        break
    fi
done

if [ -z "$KILO_DIR" ]; then
    log_error "Could not find Kilo Code extension."
    echo "  Usage: sudo bash $0 /path/to/kilocode.kilo-code-VERSION"
    exit 1
fi

log_info "Kilo Code extension: $KILO_DIR"
[ -n "$MARKDOWN_BASE" ] && log_info "Markdown base: $MARKDOWN_BASE"
[ -n "$ANTIGRAVITY_BASE" ] && log_info "Antigravity base: $ANTIGRAVITY_BASE"
echo ""

# Apply Kilo Code fix (||true so `set -e` doesn't bail on "already patched")
KILO_RESULT=0
patch_kilo_extension "$KILO_DIR" || KILO_RESULT=$?

# Apply Markdown fix
MD_RESULT=1
if [ -n "$MARKDOWN_BASE" ]; then
    MD_RESULT=0
    patch_markdown_preview "$MARKDOWN_BASE" || MD_RESULT=$?
else
    log_warn "Markdown extension base not found, skipping"
fi

# Apply Antigravity workbench CSS fix
AG_RESULT=1
if [ -n "$ANTIGRAVITY_BASE" ]; then
    AG_RESULT=0
    patch_antigravity_workbench "$ANTIGRAVITY_BASE" || AG_RESULT=$?
else
    log_warn "Antigravity base not found, skipping"
fi

echo ""
echo "============================================"
echo " Results:"
[ $KILO_RESULT -eq 0 ] && echo "  Kilo Code:    patched"
[ $KILO_RESULT -eq 2 ] && echo "  Kilo Code:    already patched"
[ $MD_RESULT -eq 0 ] && echo "  Markdown:     patched"
[ $MD_RESULT -eq 2 ] && echo "  Markdown:     already patched"
[ $AG_RESULT -eq 0 ] && echo "  Antigravity:  patched"
[ $AG_RESULT -eq 2 ] && echo "  Antigravity:  already patched"
echo "============================================"
echo ""

echo "Restart your editor completely (not just reload window)."
echo "Backups saved with suffix: $BACKUP_SUFFIX"
