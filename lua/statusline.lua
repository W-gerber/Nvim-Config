-- Lualine "bubbles" statusline.
--
-- Every color comes from `core.ui`'s palette, which is derived from the active
-- colorscheme — switching themes restyles the bar instead of leaving it neon.

local ui = require("core.ui")
local icons = require("core.icons")

local ROUNDED = { left = icons.ui.pill_left, right = icons.ui.pill_right }

--- Fixed-width transparent gap, used to float the outer bubbles off the edges.
local function spacer(width)
  return {
    function() return string.rep(" ", width) end,
    color = { bg = "NONE" },
    padding = 0,
  }
end

local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if not gitsigns then
    return nil
  end

  return {
    added = gitsigns.added,
    modified = gitsigns.changed,
    removed = gitsigns.removed,
  }
end

local function lsp_client()
  local names = {}

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client.name ~= "copilot" and client.name ~= "null-ls" then
      names[#names + 1] = client.name
    end
  end

  if #names == 0 then
    return ""
  end

  return " " .. table.concat(names, ", ")
end

local function has_lsp_client() return lsp_client() ~= "" end

local function music_segment()
  local ok, music = pcall(require, "core.music")
  return ok and music.statusline() or ""
end

--- A rounded pill on the given surface color.
---
--- Themes that declare `neon_glow` get bold pill text. A terminal cannot do the
--- bloom the original SynthWave '84 shader does, so weight is what stands in
--- for it — applied consistently across statusline, tabline and dashboard.
local function pill(component, background, foreground)
  return vim.tbl_extend("force", {
    separator = ROUNDED,
    color = { fg = foreground, bg = background, gui = ui.palette().glow and "bold" or nil },
    padding = { left = 1, right = 1 },
  }, component)
end

--- Lualine theme table built from the palette's mode colors.
local function build_theme(palette)
  local function mode_section(color)
    return {
      a = { fg = ui.contrast(color), bg = color, gui = "bold" },
      b = { fg = palette.fg, bg = "NONE" },
      c = { fg = palette.fg, bg = "NONE" },
    }
  end

  return {
    normal = mode_section(palette.modes.n),
    insert = mode_section(palette.modes.i),
    visual = mode_section(palette.modes.v),
    replace = mode_section(palette.modes.R),
    command = mode_section(palette.modes.c),
    terminal = mode_section(palette.modes.t),
    inactive = {
      a = { fg = palette.muted, bg = "NONE" },
      b = { fg = palette.muted, bg = "NONE" },
      c = { fg = palette.muted, bg = "NONE" },
    },
  }
end

local function setup()
  local ok_lualine, lualine = pcall(require, "lualine")
  if not ok_lualine then
    return
  end

  local p = ui.palette()
  local on_panel = ui.contrast(p.panel)
  local on_panel_alt = ui.contrast(p.panel_alt)
  local on_panel_soft = ui.contrast(p.panel_soft)

  lualine.setup({
    options = {
      theme = build_theme(p),
      section_separators = { left = "", right = "" },
      component_separators = { left = " ", right = " " },
      globalstatus = true,
      always_divide_middle = true,
      disabled_filetypes = { statusline = { "alpha" } },
    },
    sections = {
      lualine_a = {
        spacer(2),
        { "mode", separator = ROUNDED, padding = { left = 1, right = 1 } },
      },
      lualine_b = {
        pill({ "branch", icon = icons.git.branch }, p.panel, p.cyan),
        pill({
          "diff",
          source = diff_source,
          colored = true,
          diff_color = {
            added = { fg = p.green, bg = p.panel_alt },
            modified = { fg = p.yellow, bg = p.panel_alt },
            removed = { fg = p.red, bg = p.panel_alt },
          },
          symbols = {
            added = icons.git.added .. " ",
            modified = icons.git.modified .. " ",
            removed = icons.git.removed .. " ",
          },
        }, p.panel_alt, on_panel_alt),
        pill({
          "filename",
          path = 0,
          file_status = true,
          newfile_status = true,
          shorting_target = 40,
          symbols = {
            modified = " " .. icons.file.modified,
            readonly = " " .. icons.file.readonly,
            unnamed = "[No Name]",
            newfile = " " .. icons.file.new,
          },
        }, p.panel_soft, on_panel_soft),
      },
      lualine_c = {
        pill({
          "diagnostics",
          sources = { "nvim_diagnostic" },
          sections = { "error", "warn", "info", "hint" },
          diagnostics_color = {
            error = { fg = p.red, bg = p.panel },
            warn = { fg = p.yellow, bg = p.panel },
            info = { fg = p.cyan, bg = p.panel },
            hint = { fg = p.green, bg = p.panel },
          },
          symbols = {
            error = icons.diagnostics.error .. " ",
            warn = icons.diagnostics.warn .. " ",
            info = icons.diagnostics.info .. " ",
            hint = icons.diagnostics.hint .. " ",
          },
          update_in_insert = false,
        }, p.panel, on_panel),
      },
      lualine_x = {
        pill({
          music_segment,
          cond = function() return music_segment() ~= "" end,
          color = function()
            local ok, music = pcall(require, "core.music")
            local status = ok and music.statusline_status and music.statusline_status() or nil
            local fg = p.muted

            if status == "Playing" then
              fg = p.green
            elseif status == "Paused" then
              fg = p.yellow
            end

            return { fg = fg, bg = p.panel }
          end,
        }, p.panel, on_panel),
        pill({ lsp_client, cond = has_lsp_client }, p.panel_alt, on_panel_alt),
        pill({ "filetype", colored = true, icon_only = false }, p.panel_soft, on_panel_soft),
      },
      lualine_y = {
        pill({ "progress" }, p.panel, on_panel),
      },
      lualine_z = { spacer(2) },
    },
    inactive_sections = {
      lualine_a = { spacer(2) },
      lualine_b = { pill({ "filename", path = 0 }, p.panel, p.muted) },
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = { spacer(2) },
    },
    tabline = {},
    extensions = { "neo-tree", "lazy", "mason", "toggleterm", "trouble" },
  })

  -- The bar itself stays see-through; only the pills are painted.
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", fg = p.fg })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE", fg = p.muted })
end

setup()

ui.on_theme_change(ui.create_augroup("StatuslineTheme"), setup)

return { setup = setup }
