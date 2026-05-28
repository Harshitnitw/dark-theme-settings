#!/usr/bin/env bash
# Tier 2 installer — workbench CSS injection.
# Installs antigravity-custom.css into the Antigravity install dir
# and adds <link> tags to workbench.html + workbench-jetski-agent.html.
#
# Requires sudo because the target is under /usr/share or /Applications.
# On Antigravity update this will be reverted — re-run after each update.
#
# Usage:
#   sudo bash install.sh             # auto-detect install dir
#   sudo bash install.sh /path/to/app  # specify resources/app dir

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"
SOURCE_CSS="$SCRIPT_DIR/antigravity-custom.css"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
fatal() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[ -f "$SOURCE_CSS" ] || fatal "Source CSS missing: $SOURCE_CSS"

# Locate the app's resources/app dir
APP_PATHS=(
    "/usr/share/antigravity/resources/app"
    "/opt/Antigravity/resources/app"
    "/Applications/Antigravity.app/Contents/Resources/app"
    "/usr/share/code/resources/app"
    "/Applications/Visual Studio Code.app/Contents/Resources/app"
)
if [ -n "$1" ]; then
    APP_BASE="$1"
else
    for p in "${APP_PATHS[@]}"; do
        if [ -d "$p/out/vs/code/electron-browser/workbench" ]; then
            APP_BASE="$p"; break
        fi
    done
fi
[ -z "$APP_BASE" ] && fatal "Could not locate IDE install dir. Pass it as argument."
[ -d "$APP_BASE/out/vs/code/electron-browser/workbench" ] || fatal "No workbench dir under $APP_BASE"

WB_DIR="$APP_BASE/out/vs/code/electron-browser/workbench"
CSS_DEST="$WB_DIR/antigravity-custom.css"

info "Target: $WB_DIR"

# Install CSS (with backup if a previous copy exists)
[ -f "$CSS_DEST" ] && cp "$CSS_DEST" "${CSS_DEST}${BACKUP_SUFFIX}"
cp "$SOURCE_CSS" "$CSS_DEST"
info "Installed antigravity-custom.css"

# Inject <link> tag in each workbench HTML if not already present
for html in "$WB_DIR/workbench.html" "$WB_DIR/workbench-jetski-agent.html"; do
    [ -f "$html" ] || continue
    name=$(basename "$html")
    if grep -q "antigravity-custom.css" "$html"; then
        info "$name: already linked"
        continue
    fi
    cp "$html" "${html}${BACKUP_SUFFIX}"
    # Inject after the LAST existing <link rel="stylesheet" ...>
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
    info "$name: link injected"
done

echo
info "Restart your IDE completely (close & reopen, not just reload window)."
info "Backups suffix: $BACKUP_SUFFIX"
echo
warn "On next IDE update these files will be overwritten — re-run this script."
