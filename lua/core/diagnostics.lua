-- Diagnostic presentation.
--
-- This used to live inside plugins/lspconfig.lua, which meant the look of a
-- diagnostic depended on a *plugin* having loaded. nvim-lint publishes into the
-- same `vim.diagnostic` namespace, so a shell script linted by shellcheck in a
-- buffer with no language server attached got Neovim's defaults instead.
-- Owning the configuration here means one appearance for every producer.
--
-- The design, in short: no sign column clutter (gitsigns owns that gutter),
-- an undercurl under the offending text, and one icon-prefixed virtual text
-- chip at the end of the line. Everything else is on demand — the float under
-- `<leader>d`, or Trouble.
--
-- Colors come from `core.ui`'s palette and re-apply on theme change, like the
-- rest of the chrome. Note which groups are set: only the *derived* ones
-- (VirtualText/Underline/Floating). `core.ui.palette()` reads `DiagnosticError`
-- and friends to work out the theme's red/yellow/blue, so writing those here
-- would feed the palette its own output.

local M = {}

local all_icons = require("core.icons")
local icons = all_icons.diagnostics
local ui = require("core.ui")

local severity = vim.diagnostic.severity

local SIGNS = {
  [severity.ERROR] = icons.error,
  [severity.WARN] = icons.warn,
  [severity.INFO] = icons.info,
  [severity.HINT] = icons.hint,
}

local VIRTUAL_TEXT_HL = {
  [severity.ERROR] = "DiagnosticVirtualTextError",
  [severity.WARN] = "DiagnosticVirtualTextWarn",
  [severity.INFO] = "DiagnosticVirtualTextInfo",
  [severity.HINT] = "DiagnosticVirtualTextHint",
}

local FLOATING_HL = {
  [severity.ERROR] = "DiagnosticFloatingError",
  [severity.WARN] = "DiagnosticFloatingWarn",
  [severity.INFO] = "DiagnosticFloatingInfo",
  [severity.HINT] = "DiagnosticFloatingHint",
}

--- Icon + matching highlight for a diagnostic, for `virtual_text.prefix`.
---@param diagnostic vim.Diagnostic
---@return string prefix, string highlight
local function virtual_text_prefix(diagnostic)
  local sev = diagnostic.severity or severity.HINT
  return (SIGNS[sev] or icons.hint) .. " ", VIRTUAL_TEXT_HL[sev] or "DiagnosticVirtualTextHint"
end

--- Same, for the float — where the icon gets a trailing space of its own so the
--- message doesn't start hard against the glyph.
---@param diagnostic vim.Diagnostic
---@return string prefix, string highlight
local function float_prefix(diagnostic)
  local sev = diagnostic.severity or severity.HINT
  return (" %s  "):format(SIGNS[sev] or icons.hint), FLOATING_HL[sev] or "DiagnosticFloatingHint"
end

--- One line, collapsed whitespace, and short enough to read at the end of a
--- line of code. Multi-line messages (rustc, tsserver) are the reason virtual
--- text normally looks broken; the full text is still one `<leader>d` away.
---@param diagnostic vim.Diagnostic
---@return string
local function virtual_text_format(diagnostic)
  local message = (diagnostic.message or ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")

  local MAX = 80
  if vim.fn.strdisplaywidth(message) > MAX then
    message = vim.fn.strcharpart(message, 0, MAX) .. all_icons.ui.ellipsis
  end

  return message
end

--- Float text: the message, plus the rule that produced it as `[no-unused-vars]`
--- when the source knows one. `source = "if_many"` already adds the tool name.
---@param diagnostic vim.Diagnostic
---@return string
local function float_format(diagnostic)
  local message = (diagnostic.message or ""):gsub("%s+$", "")
  local code = diagnostic.code or (diagnostic.user_data or {}).code

  if code and code ~= "" then
    return ("%s  [%s]"):format(message, code)
  end

  return message
end

-- ---------------------------------------------------------------------------
-- Configuration
-- ---------------------------------------------------------------------------

local function configure()
  vim.diagnostic.config({
    -- The gutter belongs to gitsigns. A diagnostic already announces itself
    -- with an undercurl and an end-of-line chip; a third marker in the sign
    -- column is the thing that makes a buffer look busy.
    signs = false,

    underline = true,

    -- Diagnostics that arrive mid-keystroke are almost always stale by the time
    -- you finish the line.
    update_in_insert = false,

    -- Errors sort above warnings above hints, so the underline you see on a
    -- line with several problems is the worst one.
    severity_sort = true,

    virtual_text = {
      spacing = 4,
      prefix = virtual_text_prefix,
      format = virtual_text_format,
      source = "if_many",
      -- Hints are usually style suggestions; showing them inline on every line
      -- turns the buffer into noise. They still appear on hover and in Trouble.
      severity = { min = severity.INFO },
    },

    float = {
      border = "rounded",
      source = "if_many",
      header = "",
      prefix = float_prefix,
      format = float_format,
      focusable = false,
      severity_sort = true,
      max_width = 90,
      -- A column of air on each side of the text; without it the message sits
      -- flush against the rounded rim.
      suffix = " ",
    },

    -- `]d` / `[d` land on the diagnostic *and* show it, so navigating a file's
    -- problems doesn't need a second keystroke per stop.
    jump = { float = true },
  })
end

-- ---------------------------------------------------------------------------
-- Highlights
-- ---------------------------------------------------------------------------

local function apply_highlights()
  local p = ui.palette()
  local hl = vim.api.nvim_set_hl

  -- Deliberately not setting `DiagnosticError`/`Warn`/`Info`/`Hint`: those are
  -- the theme's own, and `core.ui.palette()` derives red/yellow/blue from them.
  local tones = {
    Error = p.red,
    Warn = p.yellow,
    Info = p.blue,
    Hint = p.cyan,
    Ok = p.green,
  }

  -- Nothing here paints a background.
  --
  -- A tinted "chip" behind virtual text looks right in a screenshot of an
  -- opaque theme and is wrong everywhere else: the tint is mixed against the
  -- theme's backdrop, so on a dark theme it *is* a dark rectangle, and with the
  -- glass preference on it sits over a terminal that has no backdrop to mix
  -- with — a black box trailing every line that has a diagnostic. Colored,
  -- italic text carries the same information and covers nothing.
  for suffix, color in pairs(tones) do
    -- Undercurl rather than a flat underline: it survives on top of Treesitter
    -- highlighting and degrades to a plain underline where the terminal has no
    -- curly variant.
    hl(0, "DiagnosticUnderline" .. suffix, { undercurl = true, sp = color })

    -- Dimmed a little from the full severity color so a wall of warnings does
    -- not out-shout the code it is describing, and italic so it reads as
    -- annotation rather than as something you could put a cursor in.
    hl(0, "DiagnosticVirtualText" .. suffix, {
      fg = ui.blend(color, p.bg, 0.88),
      bg = "NONE",
      italic = true,
    })

    -- Inside the float there is no code to compete with, so the full color.
    hl(0, "DiagnosticFloating" .. suffix, { fg = color, bg = "NONE" })

    -- Signs are off, but Trouble and the explorer still resolve these.
    hl(0, "DiagnosticSign" .. suffix, { fg = color, bg = "NONE" })

    -- Neovim 0.11's virtual_lines view (`<leader>uV`). Same rule: the message
    -- gets a color, the line under it gets nothing.
    hl(0, "DiagnosticVirtualLines" .. suffix, { fg = color, bg = "NONE" })
  end

  -- Deprecated / unnecessary code, which servers report as a tag rather than a
  -- severity. Left un-underlined on purpose — struck-through grey says "dead"
  -- better than a red squiggle does.
  hl(0, "DiagnosticDeprecated", { fg = p.muted, strikethrough = true })
  hl(0, "DiagnosticUnnecessary", { fg = ui.blend(p.muted, p.bg, 0.7), italic = true })

  -- The `K` hover and signature-help windows, so they match the diagnostic
  -- float rather than inheriting whatever the colorscheme left behind.
  hl(0, "LspInfoBorder", { fg = ui.blend(p.accent, p.bg, 0.5), bg = "NONE" })
  hl(0, "LspSignatureActiveParameter", { fg = p.accent, bold = true, underline = true })
end

-- ---------------------------------------------------------------------------
-- Hover-to-float
-- ---------------------------------------------------------------------------
--
-- Off by default: with 'updatetime' at 250ms an always-on float pops as fast as
-- the cursor moves, and it fights which-key and the cmdline for the same corner
-- of the screen. `<leader>uf` turns it on for the times you want it.

local hover_group = nil

local function set_hover_float(enabled)
  if hover_group then
    pcall(vim.api.nvim_del_augroup_by_id, hover_group)
    hover_group = nil
  end

  if not enabled then
    return
  end

  hover_group = vim.api.nvim_create_augroup("UserDiagnosticHover", { clear = true })

  vim.api.nvim_create_autocmd("CursorHold", {
    group = hover_group,
    callback = function()
      -- Never stack a second float on top of one that is already open (the
      -- hover window from `K`, a completion doc popup, ...).
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(win).relative ~= "" then
          return
        end
      end

      vim.diagnostic.open_float(nil, { scope = "cursor", focus = false })
    end,
  })
end

--- Toggle the automatic diagnostic float (`<leader>uf`).
function M.toggle_hover_float()
  vim.g.diagnostic_hover_float = not vim.g.diagnostic_hover_float
  set_hover_float(vim.g.diagnostic_hover_float)
  vim.notify(
    "Diagnostic hover float " .. (vim.g.diagnostic_hover_float and "on" or "off"),
    vim.log.levels.INFO
  )
end

-- ---------------------------------------------------------------------------

function M.setup()
  configure()
  apply_highlights()
  ui.on_theme_change(ui.create_augroup("DiagnosticHighlights"), apply_highlights)

  if vim.g.diagnostic_hover_float then
    set_hover_float(true)
  end
end

return M
