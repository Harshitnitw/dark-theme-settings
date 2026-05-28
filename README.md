# Low-contrast dark theme — Antigravity / VS Code / Cursor

Gray text on pure black. Headings and bold go **dimmer** than body, not
brighter (that's the anti-halation trick — emphasis = less luminance,
not more). Syntax highlighting and ANSI colors are preserved in editors,
terminals, and AI agent panels.

Three install tiers. Start at Tier 1 — most pain is gone after that.
Move down only if you still see bright spots.

| Tier | Touches | Survives IDE update? | Risk | What it fixes |
|---|---|---|---|---|
| **1** Settings | `~/.config/.../settings.json` | ✅ yes | none | Editor, **editor syntax tokens (keywords/strings/numbers/types/functions dimmed to match ANSI)**, side bar (incl. section headers, tree guides), activity bar (active indicator + badges), tabs (incl. modified dot + close X area), panels, title bar, status bar (incl. prominent / remote / error items), command center, autocomplete + hover widgets, command palette, dropdowns / buttons / badges, notifications, git decoration colors, terminal ANSI palette, diff editor |
| **2** Workbench CSS | `resources/app/.../workbench.html` + `.css` | ❌ no — re-run | shows cosmetic "corrupt" banner | Antigravity agent chat, all Tailwind-styled UI |
| **3** Extension CSS | `resources/app/extensions/...markdown.css` + Kilo `extension.js` | ❌ no — re-run | none functional | Markdown preview (incl. plain text in code blocks), Kilo Code chat & diff |

Color palette.

The anti-halation hierarchy (emphasis = *dimmer*, not brighter) only kicks
in where size/weight actually changes — i.e. the **markdown preview**.
The source editor view of a `.md` file shows `# Heading` and body
prose at identical visual size, so dimming the heading there would
falsely shrink it. **Source view is flat at the body color**; preview
adds the luminance steps.

| Surface | Body | h3–h6 / `**bold**` | h1 / h2 | Notes |
|---|---|---|---|---|
| **Editor** (any file, .md source) | `#7a7a7a` | `#7a7a7a` (same) | `#7a7a7a` (same) | Flat — no luminance hierarchy; size is uniform in source |
| **Markdown preview** | `#7a7a7a` | `#6a6a6a` | `#5a5a5a` | Headings/bold dim *because* size + weight already signal emphasis |
| **Terminal / TUI** | `#7a7a7a` (`terminal.foreground`) | `#6a6a6a` (`ansiBrightWhite` / SGR 1) | — | Synthetic block cursor (Claude Code / Ink) fills with `terminal.foreground` via SGR-7 reverse, so this dim level keeps it quiet |
| **UI chrome** (sidebar, status bar, panel) | `#969696` | — | — | Deliberately *brighter* than editor body so navigation is findable; content sits below chrome in luminance |

| Other | Color | Notes |
|---|---|---|
| Sub-labels (dates, citations) | `#555555` | |
| Background | `#000000` | Pure black |
| Code-block bg | `#020202` | Just barely off-black so it's distinguishable |
| Inline-code bg | `#0a0a0a` | |
| Links | `#5c758a` | Muted blue |
| Terminal red / green / yellow / blue | `#a87a7a` / `#7a9a7a` / `#8a8270` / `#5c758a` | ANSI colors preserved, dimmed but kept readable for diff hunks |

### Editor syntax token palette

The editor's TextMate token colors mirror the ANSI palette below so
code in the editor and code in the terminal sit at the same luminance.
Hue is preserved — keywords still red, strings still green, types
still blue — they just stop shouting. Operators and punctuation are
pinned to body color so dense glyph clusters (`::`, `=>`, `<>`) don't
out-shout the identifiers around them.

| Scope (TextMate) | Color | Token examples |
|---|---|---|
| `comment` | `#5a5a5a` italic | `// like this` |
| `keyword`, `keyword.control` | `#a87a7a` (dim red) | `if`, `else`, `return`, `for`, `async` |
| `keyword.operator` | `#7a7a7a` (body) | `=`, `::`, `=>`, `<`, `>` |
| `storage`, `storage.type`, `storage.modifier` | `#5c758a` (dim blue) | `let`, `const`, `fn`, `pub`, `mut`, `def`, `class` |
| `string`, `string.template` | `#7a9a7a` (dim green) | `"..."`, ``` `...` ``` |
| `constant.character.escape`, `string.regexp` | `#8a8270` | `\n`, `\t`, regex literals |
| `constant.numeric`, `constant.language` | `#8a8270` (dim yellow) | `42`, `true`, `false`, `None`, `null` |
| `entity.name.function`, `support.function` | `#5c8a8a` (dim cyan) | `main`, `println!`, `console.log` |
| `entity.name.type`, `support.type`, `support.class` | `#5c758a` (dim blue) | `Result`, `Vec<T>`, `String`, `Witness` |
| `variable.other.constant`, `constant.other` | `#8a8270` | `MAX_LEN`, UPPER_CASE constants |
| `variable`, `variable.parameter`, `variable.other.property` | `#7a7a7a` (body) | identifiers — the most common token, sits at base luminance |
| `punctuation`, `meta.brace` | `#7a7a7a` (body) | `{`, `}`, `;`, `,`, `.` |
| `entity.name.decorator`, `meta.attribute` | `#7a5c8a` (dim magenta) | `@override`, `#[derive(...)]`, `@app.route(...)` |
| `entity.name.tag`, `meta.tag` | `#a87a7a` | `<div>`, JSX/HTML/XML tags |
| `entity.other.attribute-name` | `#8a8270` | `class="..."`, JSX props |
| `invalid`, `invalid.deprecated` | `#a87a7a` italic | linter-flagged tokens |

Why these scopes specifically: TextMate scopes are language-ish — TS,
Rust, Python, and Go grammars all emit slightly different sub-scopes,
but they all share these top-level prefixes. The rules above match
`keyword.*`, `storage.*`, etc. via TextMate's prefix-match semantics,
so they cover ~90% of tokens across mainstream languages without
per-language rules. If a token in some language stays bright, find
its exact scope (Ctrl/Cmd+Shift+P → "Inspect Editor Tokens and Scopes")
and add a row.

The list is NARROW on purpose. Broad scopes like `source`, `text`, or
`text.html.markdown` would override **all** descendant token colors
and flatten syntax highlighting (same mistake as `body, body *` in
CSS). Don't add those.

### Terminal / ANSI palette (for Claude Code, oh-my-zsh, any TUI)

Claude Code with `"theme": "dark-ansi"` paints everything through the
VS Code terminal's ANSI palette below — meaning whatever you set in
`terminal.ansi*` becomes Claude Code's color scheme. Same applies to
any TUI run inside the integrated terminal. The mapping that matters:

| ANSI slot | Color | What Claude Code uses it for |
|---|---|---|
| `terminal.foreground` | `#7a7a7a` | TUI body text — set **below** editor body (`#969696`) so synthetic cursors (Claude Code / Ink draw a block via SGR-7 reverse, which fills with this color) don't outshine the surrounding glyphs |
| `terminal.ansiBlack` | `#000000` | True black backgrounds |
| `terminal.ansiBrightBlack` | `#1a1a1a` | **User input panel background** (xterm default is #808080 — halates hard on black). Also "subtle highlight" backgrounds in most TUIs |
| `terminal.ansiWhite` | `#7a7a7a` | Plain (non-bold) text — kept equal to `terminal.foreground` |
| `terminal.ansiBrightWhite` | `#6a6a6a` | **Bold text** — bold headings (`Update(...)`), line counts (`9`, `31`), emphasized words (`both`), the `●` bullet. DIMMER than body per anti-halation |
| `terminal.ansiRed` / `ansiBrightRed` | `#a87a7a` | Removed diff lines (`- removed`) — bright enough to READ inside hunks |
| `terminal.ansiGreen` / `ansiBrightGreen` | `#7a9a7a` | Added diff lines (`+ added`) — paired with red brightness for readable diffs |
| `terminal.ansiYellow` / `ansiBrightYellow` | `#8a8270` | Warnings, modified-file markers, search highlights |
| `terminal.ansiBlue` / `ansiBrightBlue` | `#5c758a` | File paths, hyperlinks |
| `terminal.ansiCyan` / `ansiBrightCyan` | `#5c8a8a` | Info, secondary highlights |
| `terminal.ansiMagenta` / `ansiBrightMagenta` | `#7a5c8a` | Strings in some highlighters |
| `terminalCursor.foreground` | `#5a5a5a` | Cursor block — dimmer than body so it doesn't pulse-flash |

### Three terminal-rendering settings that make the above actually dim

The ANSI palette alone isn't enough — xterm.js (VS Code's terminal
emulator) applies three transformations that silently brighten output.
All three must be neutralized:

```jsonc
"terminal.integrated.fontWeightBold": "normal",
"terminal.integrated.drawBoldTextInBrightColors": true,
"terminal.integrated.minimumContrastRatio": 2.5
```

- **`fontWeightBold: "normal"`** — by default xterm.js renders ANSI
  bold with a heavier font weight on top of the brighter color. The
  thicker strokes make bold tokens look brighter regardless of the
  hex value. Setting `"normal"` removes the weight bump so bold is
  signaled by *color* alone (dimmer `ansiBrightWhite`).
- **`drawBoldTextInBrightColors: true`** — this is the xterm.js
  default; set it explicitly anyway so it can't be turned off by an
  IDE-wide preference change. It's what routes ANSI bold through
  `ansiBrightWhite` so our dim color applies.
- **`minimumContrastRatio: 2.5`** — xterm.js auto-brightens any
  foreground that falls below this ratio against the background.
  `1` (off) keeps the palette exactly as authored but means SGR-2
  *dim* text (which Claude Code uses for code-block comments) ends
  up at ~1.9:1 — visible but dimmer than red diff hunks, which
  reads as "broken." `2.5` is the sweet spot: it lifts dim text
  just enough to be legible (~2.5:1 ≈ `#5a5a5a` rendered) while
  leaving the authored palette alone. The thresholds for reference:
    - body `#7a7a7a` on `#000000` ≈ **5.0:1** (untouched)
    - bold `#6a6a6a`              ≈ **3.7:1** (untouched)
    - cursor `#5a5a5a`            ≈ **3.1:1** (untouched)
    - SGR-2 dim of body           ≈ **1.9:1** → lifted to 2.5:1
  Don't set it to `4.5` (the W3C-AA default) — that would lift body
  *and* cursor, undoing the whole anti-halation calibration.

### Where ANSI bold actually comes from in Claude Code

Bold text in Claude Code's TUI output is emitted with `SGR 1`
(`\x1b[1m`). xterm.js + `drawBoldTextInBrightColors` then routes
that to `ansiBrightWhite`. So:

- The `●` bullet → bright white → `ansiBrightWhite`
- Diff filename headers (`Update(~/.config/Antigravity/...)`) → bold
  → `ansiBrightWhite`
- Numerals in line counts (`Added 9 lines, removed 31 lines`) → bold
  → `ansiBrightWhite`
- The word `both` and other prose emphasis → `**bold**` markdown
  rendered as SGR 1 → `ansiBrightWhite`

To dim any of these without dimming body text, only `ansiBrightWhite`
needs to move. Body uses `ansiWhite` separately.

---

## Tier 1 — Settings only (start here)

This is the safe, portable tier. No system files touched, no patches
needed after IDE updates.

### 1a. IDE workbench colors

1. Open your IDE's user settings.json:
   - **Linux** Antigravity: `~/.config/Antigravity/User/settings.json`
   - **Linux** VS Code:     `~/.config/Code/User/settings.json`
   - **Linux** Cursor:      `~/.config/Cursor/User/settings.json`
   - **macOS** Antigravity: `~/Library/Application Support/Antigravity/User/settings.json`
   - **macOS** VS Code:     `~/Library/Application Support/Code/User/settings.json`
   - **Windows** Antigravity: `%APPDATA%\Antigravity\User\settings.json`
   - **Windows** VS Code:   `%APPDATA%\Code\User\settings.json`
2. Merge the contents of [`tier1-settings-only/settings.snippet.json`](tier1-settings-only/settings.snippet.json).
   - If your settings.json already has `workbench.colorCustomizations`
     or `editor.tokenColorCustomizations`, merge inside those keys
     rather than replacing them.
   - The snippet ships **unscoped** (no `"[ThemeName]"` wrapper)
     because Antigravity doesn't actually register a theme named
     "Antigravity" — setting `workbench.colorTheme: "Antigravity"`
     silently falls back to the default dark theme, so any
     `"[Antigravity]"` scope would be dead weight.
   - On VS Code / Cursor, if you want overrides to revert when you
     switch themes, you *can* rewrap them in `"[Default Dark Modern]"`,
     `"[Cursor Dark]"`, etc. Otherwise leave unscoped — they apply
     to whatever theme is active.
3. Reload window (Ctrl/Cmd + Shift + P → "Reload Window").

### 1b. Claude Code CLI theme (critical)

If you use Claude Code in the terminal, its default `"theme": "dark"`
emits 24-bit RGB colors that **completely bypass** the dimmed terminal
palette from 1a. Switch it to `dark-ansi` so it uses your ANSI palette.

Edit `~/.claude/settings.json` (per [`tier1-settings-only/claude-code-settings.snippet.json`](tier1-settings-only/claude-code-settings.snippet.json)):

```json
{
  "theme": "dark-ansi"
}
```

Exit and re-launch any running Claude Code session — theme is read at
startup.

If your screenshot is now ≈ what you wanted, **stop here.**

---

## Tier 2 — Workbench CSS (Antigravity-specific bright spots)

Tier 1 can't reach the Antigravity AI agent chat, the Kilo Code panel
chrome, or anything else styled with Tailwind utility classes. Tier 2
injects custom CSS into the workbench.

Linux / macOS:

```bash
cd tier2-css-injection
sudo bash install.sh                # auto-detects /usr/share/antigravity or /Applications/...
```

Windows (PowerShell as Administrator):

```powershell
# Manual: copy antigravity-custom.css next to workbench.html, then
# add this line to workbench.html in the <head> just after the
# existing workbench.desktop.main.css <link>:
#   <link rel="stylesheet" href="./antigravity-custom.css">
#
# Path: C:\Users\<you>\AppData\Local\Programs\Antigravity\resources\app\out\vs\code\electron-browser\workbench\
```

After install:
r
1. Restart Antigravity **completely** (not just "Reload Window")
2. A cosmetic "Installation appeas corrupt" banner will appear once.
   Dismiss it. (Ctrl+Shift+P → "Dismiss Corrupt Installation Message"
   to make the banner check shut up.)
3. On Antigravity auto-update, the file is overwritten — re-run the
   installer.

---

## Tier 3 — Extension patches (Kilo Code + markdown preview)

The Kilo Code extension runs inside a webview and ignores everything
above. Same for the bundled markdown preview. These need direct file
edits.

Linux / macOS:

```bash
cd tier3-extension-patches
sudo bash install-kilo-and-markdown.sh
```

Windows:

```powershell
cd tier3-extension-patches
# Run the existing .ps1 (kept in _legacy/) — or apply manually:
#   1. Append markdown-preview.css.snippet to
#      <app>\resources\app\extensions\markdown-language-features\media\markdown.css
#   2. For Kilo Code, find its extension.js inside the extension dir
#      and inject the CSS rule (see install-kilo-and-markdown.sh
#      around line for KILO_CSS).
```

Re-run when Antigravity updates (rewrites markdown.css) and when Kilo
Code updates (rewrites extension.js).

---

## What goes where (folder map)

```
dark-theme-settings/
├── README.md                           ← you are here
├── tier1-settings-only/
│   └── settings.snippet.json           ← merge into your settings.json
├── tier2-css-injection/
│   ├── antigravity-custom.css          ← the workbench-level stylesheet
│   └── install.sh                      ← sudo bash install.sh
├── tier3-extension-patches/
│   ├── install-kilo-and-markdown.sh    ← sudo bash install-…
│   ├── markdown-preview.css.snippet    ← manual append target
│   └── (Windows .ps1 lives in _legacy/)
├── other-apps/
│   ├── google-ai-studio.css            ← bookmarklet-style CSS for AI Studio
│   ├── google-ai-studio-notes.txt
│   └── qbittorrent-darkstylesheet.qbtheme
└── _legacy/                            ← the previous folder structure;
                                          keep for archaeology, ignore otherwise
```

---

## Trade-offs

**Why not just a VS Code theme extension?** Themes can set the colors
defined by VS Code's theme API, which is what Tier 1 does. But large
parts of Antigravity's UI (the AI agent panel, the Kilo Code panel,
the markdown preview, parts of chat) are rendered via Tailwind CSS
with hardcoded colors that **the theme API cannot touch**. That's why
Tiers 2/3 exist.

**Why stay with Antigravity over VS Code / Cursor?** Antigravity gives
free access to Claude/Gemini agents. The theme situation is identical
on all three IDEs — same Electron + Tailwind problem, same patch
techniques. There's no theming benefit to switching.

**Why is bold *dimmer* than body?** On a black background, *brighter*
text creates halation (the bloom around glyphs that strains the eye
during long reading). The conventional pattern — body gray + bright
white bold — maximizes halation right where you most need to read
carefully. Flipping it (body lighter, emphasis darker) keeps the
typographic hierarchy via *contrast* without spiking luminance.

**Why preserve syntax colors?** Earlier versions of this theme used
`body, body * { color: #969696 !important }` which flattened all code
in markdown previews and Kilo Code diffs to gray. That made it harder,
not easier, to read. Current rules dim the prose container but leave
descendant token spans alone, so Pygments / shiki / TextMate colors
survive — just on a darker canvas.

**The `pre code` color trick.** VS Code's bundled markdown.css sets
`pre code { color: var(--vscode-editor-foreground) }`, which paints
*plain* text inside fenced code blocks (ASCII diagrams, unhighlighted
runs, language-less fences) bright white. To fix that without killing
syntax highlighting, the override is

```css
pre code { color: #7a7a7a; background-color: transparent !important; }
```

— color is set **without** `!important`. Source-order cascade beats
the default rule (both are specificity `0,0,2`; mine is later), but
syntax-highlighter tokens still win because they either use inline
`style="color:..."` (which beats author non-`!important`) or class
selectors with higher specificity (`.hljs-keyword`, `.token.string`,
etc.). Net effect: plain text dims to body gray, tokens keep their
hue.
