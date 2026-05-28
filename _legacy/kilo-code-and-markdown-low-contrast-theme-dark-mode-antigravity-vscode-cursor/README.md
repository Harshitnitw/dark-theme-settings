# Kilo Code + Markdown Preview Low Contrast Theme

Injects dim gray text (`#969696`) and pure black backgrounds (`#000000`) into webview HTML templates and workbench CSS to reduce eye strain and halation on dark displays.

## What it does

| Component | Fix | Method |
|---|---|---|
| **Kilo Code chat** | `#969696` text, `#000` bg | CSS injection into `extension.js` HTML template |
| **Markdown preview** | `#969696` text, `#000` bg | CSS append to `markdown.css` |
| **Antigravity agent chat** | `#969696` text | Update `antigravity-custom.css` |
| **Editor/panels/titlebar** | `#000` background | `settings.json` workbench color customizations |

The `body,body *{color:#969696!important;background-color:#000000!important}` selector overrides all text colors and backgrounds, including inline React styles.

## Quick apply (prompt for AI)

Paste this prompt to any AI assistant (Kilo Code, Claude, etc.):

```
Apply low-contrast theme to Kilo Code and Markdown preview in Antigravity/VS Code:

1. Inject this CSS into the Kilo Code extension's extension.js HTML template (before </style>):
   body,body *{color:#969696!important;background-color:#000000!important}
   h1,h2,h3,h4,h5,h6{color:#969696!important}

2. Append to markdown-language-features/media/markdown.css:
   body,body *{color:#969696!important;background-color:#000000!important}
   h1,h2,h3,h4,h5,h6{color:#969696!important}

3. Update antigravity-custom.css: change all #6b6b6b to #969696

4. Add to settings.json workbench.colorCustomizations "[Antigravity]":
   "editor.background":"#000000","sideBar.background":"#000000",
   "panel.background":"#000000","tab.activeBackground":"#000000",
   "tab.inactiveBackground":"#000000","editorGroup.background":"#000000",
   "titleBar.activeBackground":"#000000","statusBar.background":"#000000"

Files are in: $HOME/.antigravity/extensions/kilocode.kilo-code-*/dist/
and /usr/share/antigravity/resources/app/extensions/
```

## Manual usage

### Linux / macOS

```bash
# Auto-detect (sudo needed for system directories)
sudo bash apply-low-contrast.sh

# Or specify path
sudo bash apply-low-contrast.sh /home/user/.antigravity/extensions/kilocode.kilo-code-7.2.52-linux-x64
```

### Windows

```powershell
# Run as Administrator for system paths
.\apply-low-contrast.ps1

# Or specify path
.\apply-low-contrast.ps1 -Path "C:\Users\username\.vscode\extensions\kilocode.kilo-code-7.2.52"
```

## After applying

**Restart the editor completely** (not just "Reload Window"). Close and reopen the application.

## Restore backups

```bash
# Linux/macOS — restore all
for f in dist/*.js.bak.*; do cp "$f" "${f%.bak.*}"; done
for f in media/*.css.bak.*; do cp "$f" "${f%.bak.*}"; done

# Windows PowerShell
Get-ChildItem dist\*.js.bak.*,media\*.css.bak.* | ForEach-Object { Copy-Item $_.FullName ($_.Name -replace '\.bak\..*', '') }
```

## Re-run after extension update

When Kilo Code or Antigravity updates, files are replaced. Re-run the script to re-apply.

## How it works

Previous approaches (appending to CSS bundles) didn't work because extensions load CSS from compiled/bundled sources. This script:

1. **Kilo Code**: Uses `perl -i -0pe` to inject CSS into the webview HTML template string in `extension.js`, right before `</style>`.
2. **Markdown preview**: The markdown extension loads `markdown.css` as a stylesheet, so appending works.
3. **Antigravity workbench**: The `antigravity-custom.css` is loaded by `workbench.html`, so updating it directly works.
4. **Editor backgrounds**: VS Code's `workbench.colorCustomizations` in `settings.json` controls native UI colors.
