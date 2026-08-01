# Themes

Every theme in this directory is a **base46 theme table**. base46 compiles the
tables below into real highlight groups and caches them under
`stdpath("data")/base46/`.

A theme module returns:

| Field       | Purpose                                                                 |
|-------------|-------------------------------------------------------------------------|
| `base_30`   | UI chrome colors — floats, menus, statusline, git signs, folder icons     |
| `base_16`   | Syntax colors — see the slot table below                                  |
| `type`      | `"dark"` or `"light"`; sets `'background'`                                |
| `polish_hl` | Per-integration highlight overrides, keyed by base46 integration name     |
| `terminal`  | *(this config)* ANSI colors 0–15 for `:terminal`                          |
| `neon_glow` | *(this config)* opt-in extra emphasis on chrome; see `lua/core/ui.lua`    |

Themes must end with `base46.override_theme(M, "<id>")` so per-user overrides
from `nvconfig.base46.changed_themes` still apply.

## base_16 slot → highlight group

This is the mapping base46 actually uses (`base46/integrations/syntax.lua` and
`.../treesitter.lua`). Knowing it is the difference between a theme that looks
right and one that needs fifty `polish_hl` entries.

| Slot     | Drives                                                                          |
|----------|---------------------------------------------------------------------------------|
| `base00` | editor background                                                                |
| `base01` | raised surface (`Todo` bg, terminal black)                                       |
| `base02` | selection surface                                                                |
| `base03` | dim grey (terminal bright black)                                                 |
| `base04` | `@definition` underline                                                          |
| `base05` | default foreground, `Variable`, `Operator`, `@variable`, `@text`                 |
| `base06` | lighter foreground                                                               |
| `base07` | lightest foreground (terminal white)                                             |
| `base08` | `Identifier`, `Statement`, `@variable.parameter`, `@variable.member`, `@property`, `@module`, `@tag.attribute`, `@markup.link`, `@markup.list` |
| `base09` | `Constant`, `Number`, `Boolean`, `Float`, `@constant`, `@number`, `@variable.builtin` |
| `base0A` | `Type`, `Typedef`, `StorageClass`, `Label`, `PreProc`, `Repeat`, `Tag`, `@attribute`, `@keyword.repeat`, `@keyword.storage`, `@type.builtin` |
| `base0B` | `String`, `@string`, `@symbol`                                                   |
| `base0C` | `Special`, `@string.regex`, `@string.escape`, `@constructor`, `@markup.link.label` |
| `base0D` | `Function`, `Include`, `@function.*`, `@markup.heading`                          |
| `base0E` | `Keyword`, `Conditional`, `Structure`, `Define`, `@keyword.*`                    |
| `base0F` | `Delimiter`, `SpecialChar`, `@punctuation.*`, `@annotation`, `@tag.delimiter`    |

Note `base_30.grey_fg` — not a `base_16` slot — is what colors `@comment`.

## polish_hl integration names

`polish_hl` keys must match a base46 integration file name exactly, or the block
is silently ignored. The useful ones here:

`syntax` · `treesitter` · `defaults` · `lsp` · `git` · `cmp` · `telescope` ·
`mason` · `devicons` · `statusline` · `tbline` · `whichkey` · `blankline`

> Spelling matters. base46's own `chadracula` theme has a `treesiter` typo that
> makes its entire treesitter block a no-op — don't copy that pattern.

## Files

| File                | What it is                                                        |
|---------------------|-------------------------------------------------------------------|
| `neon_vommit.lua`   | Port of the Neon Vommit VS Code theme (full palette + polish)      |
| `synthwave84.lua`   | Port of SynthWave '84 (full palette + polish)                      |
| `neon_commit.lua`   | The config's original house theme, built on `lua/theme.lua`        |
| `dracula.lua`       | Thin wrapper re-exporting base46's `chadracula` under a nicer id   |
| `tokyonight.lua`    | Override hooks for base46's built-in `tokyonight` (empty by default) |
| `default_light.lua` | Override hooks for base46's built-in `default-light` (empty by default) |

The last two are patch files, not themes: base46 supplies the real palette and
these are merged over it through `changed_themes` in `lua/nvconfig.lua`. Empty
tables change nothing, so they sit there until you want to recolor something.

## Adding a theme

1. Drop `lua/themes/<id>.lua` here returning the table described above.
2. Register it in `lua/theme_switcher/themes.lua` with a display name and an
   8-color swatch for the picker.
3. `<leader>th` → it appears, with live preview.

For a theme that is an ordinary colorscheme plugin instead, skip step 1 and set
`kind = "colorscheme"` on the registry entry.
