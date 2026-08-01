-- which-key, styled as a frosted glass panel.
--
-- Three things make that work in a terminal, none of which a fully transparent
-- popup can do: a pane with a real background (`winblend` needs something to
-- frost — with none, the buffer just shows through unchanged), a beveled rim
-- lit along the top and shadowed along the bottom, and a single accent chip for
-- the breadcrumb title. The pane is `ui.frost()`, deliberately neutral: see the
-- note on that function for why panel-sized surfaces do not take the accent.
--
-- Everything else comes from `core.ui`'s palette, so the popup restyles with
-- the theme like the rest of the chrome.

local icons = require("core.icons")

-- Icons are colored per key *family* rather than one mapping at a time: every
-- entry under <leader>g is git-orange, everything under <leader>f find-green.
-- The popup then reads as grouped before you have read a single label, and the
-- spec below stays a plain list of glyphs.
--
-- Values are which-key's nine named colors; `apply_which_key_highlights()` maps
-- those onto the palette.
local FAMILY_COLORS = {
  ["<leader>?"] = "grey", -- Help
  ["<leader>a"] = "purple", -- Claude Code
  ["<leader>b"] = "cyan", -- Buffers
  ["<leader>c"] = "yellow", -- Code
  ["<leader>D"] = "red", -- Debug
  ["<leader>d"] = "green", -- Diagnostics
  ["<leader>e"] = "blue", -- Explorer
  ["<leader>f"] = "green", -- Find
  ["<leader>g"] = "orange", -- Git
  ["<leader>h"] = "blue", -- Horizontal split
  ["<leader>l"] = "orange", -- Lazygit
  ["<leader>m"] = "purple", -- Music
  ["<leader>q"] = "red", -- Close window
  ["<leader>r"] = "yellow", -- Rename
  ["<leader>s"] = "azure", -- Sessions
  ["<leader>t"] = "cyan", -- Tools
  ["<leader>u"] = "azure", -- UI toggles
  ["<leader>v"] = "blue", -- Vertical split
  ["<leader>w"] = "blue", -- Window picker
  ["<leader>x"] = "red", -- Trouble
}

--- The family color for `lhs`; the longest matching prefix wins, which is what
--- keeps `<leader>D` (Debug) out of `<leader>d`'s hands.
---@param lhs string
---@return string|nil
local function family_color(lhs)
  local color, length = nil, 0

  for prefix, name in pairs(FAMILY_COLORS) do
    if #prefix > length and vim.startswith(lhs, prefix) then
      color, length = name, #prefix
    end
  end

  return color
end

--- Give every plain icon glyph in `spec` its family color.
---
--- Entries with no icon at all are left alone on purpose: which-key matches
--- those against its own rules, which come with sensible colors already.
---@param spec table[]
---@return table[]
local function colorize(spec)
  for _, entry in ipairs(spec) do
    if type(entry.icon) == "string" then
      entry.icon = { icon = entry.icon, color = family_color(entry[1]) }
    end
  end

  return spec
end

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer keymaps",
      mode = "n",
    },
  },
  config = function()
    local ok, wk = pcall(require, "which-key")
    if not ok then
      return
    end

    local ui = require("core.ui")

    local function apply_which_key_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl

      -- The pane itself. With the glass preference on this is `NONE`, so the
      -- terminal's own acrylic/blur shows through the popup instead of a sheet
      -- of Neovim's making; the rim, the title chip and the text carry the
      -- panel on their own. See `ui.pane_bg()`.
      local pane = ui.pane_bg(0.1)

      -- Rim tones are mixed against the theme's backdrop rather than the pane:
      -- once the pane is `NONE` there is no color there to mix with.
      hl(0, "WhichKeyNormal", { fg = p.fg, bg = pane })
      hl(0, "WhichKeyBorder", { fg = ui.blend(p.accent, p.bg, 0.55), bg = pane })
      hl(0, "WhichKeyBorderTop", { fg = ui.blend(p.accent, p.fg, 0.7), bg = pane })
      hl(0, "WhichKeyBorderBottom", { fg = ui.blend(p.muted, p.bg, 0.6), bg = pane })

      -- The breadcrumb rides in the top rim, so it is a filled chip rather than
      -- bare text — otherwise it reads as a gap in the border.
      hl(0, "WhichKeyTitle", { fg = ui.contrast(p.accent), bg = p.accent, bold = true })

      -- Keys are the brightest thing in the pane; separators the faintest, so
      -- the eye goes key → icon → label.
      hl(0, "WhichKey", { fg = p.accent, bold = true })
      hl(0, "WhichKeySeparator", { fg = ui.blend(p.muted, p.bg, 0.5) })
      -- Always bold: on themes where `purple` lands close to the foreground,
      -- weight is the only thing left telling a group from a mapping.
      hl(0, "WhichKeyGroup", { fg = p.purple, bold = true })
      hl(0, "WhichKeyDesc", { fg = p.fg })
      hl(0, "WhichKeyValue", { fg = p.muted, italic = true })

      -- which-key's nine named icon colors, mapped onto the palette so a family
      -- keeps its hue under every theme.
      for suffix, color in pairs({
        [""] = ui.blend(p.accent, p.fg, 0.6),
        Azure = ui.blend(p.blue, p.cyan, 0.5),
        Blue = p.blue,
        Cyan = p.cyan,
        Green = p.green,
        Grey = p.muted,
        Orange = p.orange,
        Purple = p.purple,
        Red = p.red,
        Yellow = p.yellow,
      }) do
        hl(0, "WhichKeyIcon" .. suffix, { fg = color })
      end
    end

    apply_which_key_highlights()

    wk.setup({
      preset = "modern",
      delay = function(ctx) return ctx.plugin and 0 or 180 end,
      triggers = {
        { "<leader>", mode = { "n", "v" } },
      },
      expand = 1,
      plugins = {
        presets = {
          windows = true,
          nav = true,
          z = true,
          g = true,
        },
        spelling = { enabled = false },
      },
      win = {
        border = ui.glass_border("WhichKey"),
        title = true,
        title_pos = "center",
        no_overlap = true,
        -- Glass wants air around its content; the extra column on each side is
        -- what keeps the key column off the rim.
        padding = { 1, 3 },
        wo = {
          -- Deliberately 0: blending would composite the popup against the
          -- editor cells below it, which is the one thing that *stops* a
          -- transparent terminal from showing through. See `ui.pane_bg()`.
          winblend = 0,
        },
      },
      layout = {
        width = { min = 26, max = 42 },
        spacing = 4,
      },
      icons = {
        breadcrumb = icons.ui.chevron_right,
        separator = icons.ui.separator,
        group = "", -- groups are told apart by color and their own icon
        ellipsis = icons.ui.ellipsis,
        mappings = true,
        colors = true,
        keys = {
          Space = "Neovim ",
          CR = "RET ",
          Esc = "ESC ",
          Tab = "TAB ",
        },
      },
      -- Both of these draw into a second, borderless float that which-key
      -- creates without our `wo` options — it would sit inside the pane
      -- unblended, as a visible opaque strip across the bottom.
      show_help = false,
      show_keys = false,
    })

    -- <leader>? is declared in this spec's `keys` (which is also what loads
    -- which-key on demand); mapping it again here only created a duplicate.

    local which_key_group = ui.create_augroup("WhichKeyThemeHighlights")
    ui.on_theme_change(which_key_group, apply_which_key_highlights)

    wk.add(colorize({
      -- Claude Code
      { "<leader>a", group = "Claude Code", icon = "󰚩" },
      { "<leader>ac", desc = "Toggle Claude", icon = "󰚩" },
      { "<leader>af", desc = "Focus Claude", icon = "󰈈" },
      { "<leader>ar", desc = "Resume Claude", icon = "󰜉" },
      { "<leader>aC", desc = "Continue Claude", icon = "󰐊" },
      { "<leader>am", desc = "Select model", icon = "󰍛" },
      { "<leader>ab", desc = "Add current buffer", icon = "󰐕" },
      { "<leader>as", desc = "Send selection", icon = "󰒊", mode = "v" },
      { "<leader>aa", desc = "Accept diff", icon = "󰄬" },
      { "<leader>ad", desc = "Deny diff", icon = "󰅖" },

      -- Buffers
      { "<leader>?", desc = "Buffer keymaps", icon = "󰋖" },
      { "<leader>b", group = "Buffers", icon = "󰓩" },
      { "<leader>bn", desc = "New buffer", icon = "󰈔" },
      { "<leader>bc", desc = "Close buffer", icon = "󰅖" },
      { "<leader>bC", desc = "Force close buffer", icon = "󱎘" },
      { "<leader>bo", desc = "Close other buffers", icon = "󰈩" },
      { "<leader>bO", desc = "Force close other buffers", icon = "󰈩" },

      -- Code (LSP actions)
      { "<leader>c", group = "Code", icon = "󰘦" },
      { "<leader>ca", desc = "Code action", icon = "󰌵", mode = { "n", "v" } },
      { "<leader>cf", desc = "Format buffer / selection", icon = "󰉢", mode = { "n", "v" } },
      { "<leader>cw", desc = "Format and write", icon = "󰆓" },
      { "<leader>cF", desc = "Toggle format on save", icon = "\u{f0450}" },
      { "<leader>ch", desc = "Toggle inlay hints", icon = "\u{f0335}" },
      { "<leader>cl", desc = "Lint buffer", icon = "\u{f0e0e}" },
      { "<leader>cs", desc = "Swap argument next", icon = "\u{f0bc4}" },
      { "<leader>cS", desc = "Swap argument previous", icon = "\u{f0bc3}" },

      -- Debugger (plugins/dap.lua)
      { "<leader>D", group = "Debug", icon = "\u{f0868}" },
      { "<leader>Db", desc = "Toggle breakpoint", icon = "\u{f0403}" },
      { "<leader>DB", desc = "Conditional breakpoint", icon = "\u{f0405}" },
      { "<leader>Dc", desc = "Continue / start", icon = "󰐊" },
      { "<leader>Di", desc = "Step into", icon = "\u{f0045}" },
      { "<leader>Do", desc = "Step over", icon = "\u{f0044}" },
      { "<leader>DO", desc = "Step out", icon = "\u{f0046}" },
      { "<leader>Dr", desc = "Toggle REPL", icon = "󰆍" },
      { "<leader>Dl", desc = "Run last configuration", icon = "󰜉" },
      { "<leader>Dt", desc = "Terminate session", icon = "󰓛" },
      { "<leader>Du", desc = "Toggle debugger UI", icon = "\u{f0c9}" },
      { "<leader>De", desc = "Evaluate expression", icon = "󰘦", mode = { "n", "v" } },

      -- LSP / diagnostics
      { "<leader>rn", desc = "Rename symbol", icon = "󰑕" },
      { "<leader>d", desc = "Line diagnostics", icon = "󰒡" },

      -- File explorer
      { "<leader>e", desc = "Explorer", icon = "󰙅" },

      -- Telescope
      { "<leader>f", group = "Find", icon = "󰍉" },
      { "<leader>ff", desc = "Files (workspace)", icon = "󰈞" },
      { "<leader>fg", desc = "Grep (workspace)", icon = "󰈬" },
      { "<leader>fe", desc = "File browser (workspace)", icon = "󰝰" },
      { "<leader>fE", desc = "File browser (current file)", icon = "󰉖" },
      { "<leader>fw", desc = "Grep word under cursor", icon = "󰈬" },
      { "<leader>fb", desc = "Open buffers", icon = "󰈚" },
      { "<leader>fr", desc = "Recent files", icon = "\u{f0954}" },
      { "<leader>fh", desc = "Help tags", icon = "󰋖" },
      { "<leader>fk", desc = "Keymaps", icon = "\u{f030c}" },
      { "<leader>fc", desc = "Commands", icon = "󰘦" },
      { "<leader>fd", desc = "Diagnostics", icon = "󰒡" },
      { "<leader>fs", desc = "Document symbols", icon = "󰘦" },
      { "<leader>f/", desc = "Search in buffer", icon = "󰍉" },
      { "<leader>fR", desc = "Resume last picker", icon = "\u{f0450}" },
      { "<leader>fo", desc = "Open folder (workspace)", icon = "󰝰" },
      { "<leader>ft", desc = "Todo comments", icon = "\u{f00c}" },
      { "<leader>fT", desc = "Todo / Fix / Fixme", icon = "\u{f188}" },

      -- Git (gitsigns)
      { "<leader>g", group = "Git", icon = "󰊢" },
      { "<leader>gs", desc = "Stage hunk (toggle)", icon = "󰐕", mode = { "n", "v" } },
      { "<leader>gr", desc = "Reset hunk", icon = "󰕌", mode = { "n", "v" } },
      { "<leader>gS", desc = "Stage buffer", icon = "󰈚" },
      { "<leader>gR", desc = "Reset buffer", icon = "󰕌" },
      { "<leader>gp", desc = "Preview hunk", icon = "󰈈" },
      { "<leader>gb", desc = "Blame line", icon = "󰜘" },
      { "<leader>gB", desc = "Toggle inline blame", icon = "󰜘" },
      { "<leader>gd", desc = "Diff against index", icon = "\u{f0200}" },
      { "<leader>gD", desc = "Diff against last commit", icon = "\u{f0200}" },

      -- Music (core/music.lua)
      { "<leader>m", group = "Music", icon = "󰝚" },
      { "<leader>mm", desc = "Toggle music panel", icon = "󰝚" },
      { "<leader>mp", desc = "Play / pause", icon = "󰐊" },
      { "<leader>mn", desc = "Next track", icon = "󰒭" },
      { "<leader>mb", desc = "Previous track", icon = "󰒮" },
      { "<leader>mS", desc = "Stop", icon = "󰓛" },
      { "<leader>mu", desc = "Volume up", icon = "󰝝" },
      { "<leader>md", desc = "Volume down", icon = "󰝞" },
      { "<leader>mv", desc = "Set volume", icon = "󰕾" },

      -- Lazygit wrapper
      { "<leader>l", group = "Lazygit", icon = "󰊢" },
      { "<leader>lg", desc = "Open Lazygit", icon = "󰖳" },
      { "<leader>lG", desc = "Current file in Lazygit", icon = "󰈙" },

      -- Windows
      { "<leader>q", desc = "Close window", icon = "󰅖" },
      { "<leader>vs", desc = "Vertical split (pick window)", icon = "\u{f0bdc}" },
      { "<leader>hs", desc = "Horizontal split (pick window)", icon = "\u{f0bdb}" },
      { "<leader>wp", desc = "Jump to window", icon = "\u{f0bdc}" },

      -- Sessions. Todo search used to live here too; it moved to <leader>f
      -- so this prefix means exactly one thing.
      { "<leader>s", group = "Sessions", icon = "󱂬" },
      { "<leader>sl", desc = "Load session", icon = "󰦛" },
      { "<leader>ss", desc = "Save session", icon = "󰆓" },
      { "<leader>sd", desc = "Delete session", icon = "󰆴" },

      -- Tools / misc
      { "<leader>t", group = "Tools", icon = "󱁤" },
      { "<leader>tt", desc = "Toggle terminal", icon = "󰆍" },
      { "<leader>th", desc = "Theme picker", icon = "󰏘" },

      -- UI toggles
      { "<leader>u", group = "UI toggles", icon = "\u{f0335}" },
      { "<leader>ub", desc = "Toggle transparency", icon = "\u{f03d8}" },
      { "<leader>uw", desc = "Toggle line wrap", icon = "\u{f0e7b}" },
      { "<leader>un", desc = "Toggle relative numbers", icon = "\u{f0771}" },
      { "<leader>ud", desc = "Toggle diagnostics", icon = "󰒡" },
      { "<leader>uf", desc = "Toggle diagnostic float", icon = "\u{f0559}" },
      { "<leader>uV", desc = "Toggle diagnostic virtual lines", icon = "\u{f0e7b}" },
      { "<leader>uv", desc = "Toggle window dimming", icon = "\u{f0335}" },
      { "<leader>ua", desc = "Toggle dashboard style", icon = "\u{f0f3d}" },

      -- Trouble (diagnostics UI)
      { "<leader>x", group = "Trouble", icon = "󱍼" },
      { "<leader>xx", desc = "Diagnostics", icon = "󰒡" },
      { "<leader>xX", desc = "Buffer diagnostics", icon = "󰈙" },
      { "<leader>xs", desc = "Symbols", icon = "󰘦" },
      { "<leader>xr", desc = "LSP list", icon = "󰒋" },
      { "<leader>xL", desc = "Location list", icon = "󰈚" },
      { "<leader>xQ", desc = "Quickfix list", icon = "󰁨" },
      { "<leader>xt", desc = "Todo (Trouble)", icon = "\u{f00c}" },
      { "<leader>xT", desc = "Todo / Fix / Fixme (Trouble)", icon = "\u{f188}" },
      { "<leader>xq", desc = "Todo (quickfix)", icon = "󰁨" },
      { "<leader>xl", desc = "Todo (loclist)", icon = "󰈚" },

      -- Surround (mini.surround). Under `gs` rather than the plugin's default
      -- bare `s`, which is Flash's jump key.
      { "gs", group = "Surround", icon = "\u{f0b76}" },
      { "gsa", desc = "Add surrounding", icon = "\u{f0415}", mode = { "n", "v" } },
      { "gsd", desc = "Delete surrounding", icon = "\u{f0413}" },
      { "gsr", desc = "Replace surrounding", icon = "\u{f0450}" },
      { "gsf", desc = "Find surrounding (right)", icon = "󰍉" },
      { "gsF", desc = "Find surrounding (left)", icon = "󰍉" },
      { "gsh", desc = "Highlight surrounding", icon = "\u{f0335}" },
      { "gsn", desc = "Update search lines", icon = "\u{f0e7b}" },

      -- Bracket motions. Lowercase pairs are "things in the file" (hunks,
      -- diagnostics, todos); uppercase is reserved for structural jumps that
      -- would otherwise collide, e.g. ]C for classes vs ]c for git hunks.
      { "]b", desc = "Next buffer" },
      { "[b", desc = "Previous buffer" },
      { "]c", desc = "Next git hunk" },
      { "[c", desc = "Previous git hunk" },
      { "]d", desc = "Next diagnostic" },
      { "[d", desc = "Previous diagnostic" },
      { "]e", desc = "Next error" },
      { "[e", desc = "Previous error" },
      { "]t", desc = "Next todo comment" },
      { "[t", desc = "Previous todo comment" },
      { "]f", desc = "Next function" },
      { "[f", desc = "Previous function" },
      { "]C", desc = "Next class" },
      { "[C", desc = "Previous class" },
      { "]a", desc = "Next argument" },
      { "[a", desc = "Previous argument" },
    }))
  end,
}
