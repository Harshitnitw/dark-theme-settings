#!/usr/bin/env bash
# Tier 3 — Extension/preview CSS patches.
# Patches two things that workbench CSS injection cannot reach:
#   (a) Kilo Code extension's webview (its HTML lives inside a JS string
#       in extension.js — we inject CSS before </style>)
#   (b) The built-in Markdown Preview (we append to its markdown.css)
#
# Both patches keep SYNTAX HIGHLIGHTING ON: we dim prose + headings +
# inline code, but leave fenced <pre><code> foregrounds alone so token
# colors (keywords, strings, types) survive. Kilo's diff red/green
# backgrounds get dimmed but stay distinguishable.
#
# Re-run after Antigravity updates (markdown CSS) and after Kilo Code
# extension updates (extension.js).
#
# Usage:
#   sudo bash install-kilo-and-markdown.sh
#   sudo bash install-kilo-and-markdown.sh /path/to/kilocode.kilo-code-VERSION

set -e
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# ─── Resolve user home under sudo ─────────────────────────────────────
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME="$HOME"
fi

# ─── Inline CSS rules (kept consistent with tier2 stylesheet) ─────────
# Kilo Code: minified for injection into JS string
KILO_CSS='body{color:#969696!important;background-color:#000000!important}h1,h2,h3,h4,h5,h6,strong,b{color:#8a8a8a!important;font-weight:500!important}h1,h2{color:#7a7a7a!important}:not(pre)>code{color:#8a8a8a!important;background-color:#0a0a0a!important}pre{background-color:#020202!important}pre code{color:#969696;background-color:transparent!important}.bg-green-500,.bg-green-600{background-color:#0a150a!important}.bg-red-500,.bg-red-600{background-color:#150a0a!important}'

# Markdown preview: pretty-printed for readability
MD_CSS='
/* ============================================================
 * Low Contrast Text Overrides — anti-halation
 * Body + prose go dim gray on black; bold/headings DIMMER than body.
 * Fenced code blocks keep syntax-highlight colors (only bg changes).
 * ============================================================ */
body { color: #969696 !important; background-color: #000000 !important; }
h1, h2, h3, h4, h5, h6, strong, b { color: #8a8a8a !important; font-weight: 500 !important; }
h1, h2 { color: #7a7a7a !important; }
a { color: #5c758a !important; }
blockquote { color: #8a8a8a !important; border-left-color: #333 !important; background-color: #050505 !important; }
hr { border-color: #333 !important; }
table { border-color: #1a1a1a !important; }
table th { color: #8a8a8a !important; background-color: #050505 !important; }
table td { color: #969696 !important; background-color: #000000 !important; }
:not(pre) > code { color: #8a8a8a !important; background-color: #0a0a0a !important; border: 1px solid #151515 !important; padding: 1px 4px !important; }
pre { background-color: #020202 !important; border: 1px solid #0a0a0a !important; }
pre code { color: #969696; background-color: transparent !important; }
'

# ─── Patch functions ──────────────────────────────────────────────────
patch_kilo() {
    local ext_dir="$1"
    local js="$ext_dir/dist/extension.js"
    [ -f "$js" ] || { warn "Kilo extension.js not found: $js"; return 1; }
    if grep -q "background-color:#000000!important" "$js"; then
        info "Kilo Code already patched"
        return 2
    fi
    cp "$js" "${js}${BACKUP_SUFFIX}"
    perl -i -0pe "s/(  <\/style>)/${KILO_CSS}\n\$1/" "$js"
    info "Kilo Code patched ($js)"
}

patch_markdown() {
    local app_base="$1"
    local css="$app_base/extensions/markdown-language-features/media/markdown.css"
    [ -f "$css" ] || { warn "Markdown CSS not found: $css"; return 1; }
    if grep -q "Low Contrast Text Overrides" "$css"; then
        info "Markdown preview already patched"
        return 2
    fi
    cp "$css" "${css}${BACKUP_SUFFIX}"
    printf '%s\n' "$MD_CSS" >> "$css"
    info "Markdown preview patched ($css)"
}

# ─── Locate paths ─────────────────────────────────────────────────────
USER_EXT_PATHS=(
    "$USER_HOME/.antigravity/extensions"
    "$USER_HOME/.vscode/extensions"
    "$USER_HOME/.cursor/extensions"
    "$USER_HOME/.windsurf/extensions"
)
SYSTEM_APP_PATHS=(
    "/usr/share/antigravity/resources/app"
    "/opt/Antigravity/resources/app"
    "/Applications/Antigravity.app/Contents/Resources/app"
    "/usr/share/code/resources/app"
    "/Applications/Visual Studio Code.app/Contents/Resources/app"
)

# Find Kilo extension dir
KILO_DIR="${1:-}"
if [ -z "$KILO_DIR" ]; then
    for base in "${USER_EXT_PATHS[@]}"; do
        [ -d "$base" ] || continue
        found=$(find "$base" -maxdepth 1 -type d -name "kilocode.kilo-code-*" 2>/dev/null | head -1)
        if [ -n "$found" ]; then KILO_DIR="$found"; break; fi
    done
fi

# Find markdown extension's app base
APP_BASE=""
for p in "${SYSTEM_APP_PATHS[@]}"; do
    if [ -d "$p/extensions/markdown-language-features" ]; then APP_BASE="$p"; break; fi
done

echo "============================================"
echo " Tier 3: Kilo Code + Markdown Preview patch"
echo "============================================"
[ -n "$KILO_DIR" ] && info "Kilo: $KILO_DIR" || warn "Kilo not found, will skip"
[ -n "$APP_BASE" ] && info "Markdown base: $APP_BASE" || warn "Markdown base not found, will skip"

KILO_RC=0; MD_RC=0
if [ -n "$KILO_DIR" ]; then patch_kilo "$KILO_DIR" || KILO_RC=$?; else KILO_RC=1; fi
if [ -n "$APP_BASE" ]; then patch_markdown "$APP_BASE" || MD_RC=$?; else MD_RC=1; fi

echo
echo "============================================"
case $KILO_RC in
    0) echo "  Kilo Code:    patched" ;;
    2) echo "  Kilo Code:    already patched" ;;
    *) echo "  Kilo Code:    SKIPPED" ;;
esac
case $MD_RC in
    0) echo "  Markdown:     patched" ;;
    2) echo "  Markdown:     already patched" ;;
    *) echo "  Markdown:     SKIPPED" ;;
esac
echo "============================================"
echo
echo "Restart your editor completely (close & reopen)."
echo "Backups suffix: $BACKUP_SUFFIX"
