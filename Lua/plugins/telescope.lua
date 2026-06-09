local function shade_hex(hex, factor)
  if type(hex) ~= "string" then
    return hex
  end

  local value = hex:gsub("#", "")
  if #value ~= 6 then
    return hex
  end

  local r = tonumber(value:sub(1, 2), 16)
  local g = tonumber(value:sub(3, 4), 16)
  local b = tonumber(value:sub(5, 6), 16)
  if not r or not g or not b then
    return hex
  end

  local function clamp(channel)
    return math.max(0, math.min(255, math.floor(channel * factor + 0.5)))
  end

  return string.format("#%02x%02x%02x", clamp(r), clamp(g), clamp(b))
end

local function contrast_text(hex)
  if type(hex) ~= "string" then
    return "#ffffff"
  end

  local value = hex:gsub("#", "")
  if #value ~= 6 then
    return "#ffffff"
  end

  local r = tonumber(value:sub(1, 2), 16)
  local g = tonumber(value:sub(3, 4), 16)
  local b = tonumber(value:sub(5, 6), 16)
  if not r or not g or not b then
    return "#ffffff"
  end

  local brightness = (r * 299 + g * 587 + b * 114) / 1000
  return brightness >= 150 and "#0f172a" or "#f8fafc"
end

local function finder_path(_, path)
  local name = vim.fn.fnamemodify(path, ":t")
  local parent = vim.fn.fnamemodify(path, ":h")

  if parent == "." or parent == "" then
    return name
  end

  parent = vim.fn.fnamemodify(parent, ":~:.")
  return string.format("%s  󰉋 %s", name, parent)
end

local function open_find_files()
  local builtin = require("telescope.builtin")
  local utils = require("core.utils")

  builtin.find_files({
    cwd = utils.everything,
    hidden = true,
    no_ignore = true,
    prompt_title = "Files • " .. utils.everything_label,
    results_title = "Root Files",
    preview_title = "Preview",
    layout_strategy = "horizontal",
    sorting_strategy = "ascending",
    path_display = finder_path,
    layout_config = {
      width = 0.90,
      height = 0.84,
      prompt_position = "top",
      horizontal = {
        preview_width = 0.52,
      },
    },
  })
end

local function open_live_grep()
  local builtin = require("telescope.builtin")
  local utils = require("core.utils")

  builtin.live_grep({
    cwd = utils.everything,
    prompt_title = "Grep • " .. utils.everything_label,
    results_title = "Matches",
    preview_title = "Context",
    layout_strategy = "horizontal",
    sorting_strategy = "ascending",
    path_display = finder_path,
    layout_config = {
      width = 0.95,
      height = 0.88,
      prompt_position = "top",
      horizontal = {
        preview_width = 0.60,
      },
    },
    additional_args = function()
      return { "--hidden", "--glob", "!.git/*" }
    end,
  })
end

return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "Telescope" },
  keys = {
    { "<leader>ff", open_find_files, desc = "Telescope: Find files" },
    { "<leader>fg", open_live_grep, desc = "Telescope: Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Telescope: Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Telescope: Help tags" },
  },
  config = function()
    local ui = require("core.ui")
    local telescope = require("telescope")
    local utils = require("core.utils")

    telescope.setup({
      defaults = {
        cwd = utils.everything,
        path_display = finder_path,
        layout_strategy = "horizontal",
        layout_config = {
          flex = { flip_columns = 140 },
          horizontal = {
            preview_width = 0.56,
            preview_cutoff = 100,
          },
          vertical = { preview_height = 0.52 },
          width = 0.92,
          height = 0.86,
          prompt_position = "top",
        },
        sorting_strategy = "ascending",
        dynamic_preview_title = true,
        prompt_prefix = "󰍉  ",
        selection_caret = "▎ ",
        entry_prefix = "  ",
        winblend = 0,
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        file_ignore_patterns = { "%.git/", "node_modules/", "dist/", "build/", "target/" },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-d>"] = "preview_scrolling_down",
            ["<C-u>"] = "preview_scrolling_up",
            ["<C-c>"] = "close",
            ["<Esc>"] = "close",
          },
          n = {
            ["q"] = "close",
            ["<C-d>"] = "preview_scrolling_down",
            ["<C-u>"] = "preview_scrolling_up",
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
          no_ignore = true,
          prompt_title = "Files",
          results_title = "Results",
          preview_title = "Preview",
          layout_strategy = "horizontal",
          path_display = finder_path,
          layout_config = {
            prompt_position = "top",
            horizontal = {
              preview_width = 0.52,
            },
          },
        },
        live_grep = {
          only_sort_text = true,
          layout_strategy = "horizontal",
          prompt_title = "Grep",
          results_title = "Matches",
          preview_title = "Context",
          path_display = finder_path,
          additional_args = function()
            return { "--hidden", "--glob", "!.git/*" }
          end,
          layout_config = {
            prompt_position = "top",
            width = 0.90,
            height = 0.85,
            horizontal = {
              preview_width = 0.55,
            },
          },
        },
        buffers = {
          sort_mru = true,
          ignore_current_buffer = true,
          previewer = false,
        },
      },
    })

    -- Theme-aware telescope highlights (re-applied on ColorScheme)
    local function apply_telescope_highlights()
      local palette = ui.float_palette()
      local border_palette = ui.utility_palette()
      local is_dark = vim.o.background ~= "light"
      local panel_bg = "NONE"
      local hl = vim.api.nvim_set_hl
      local selection_bg = is_dark and shade_hex(palette.selection_bg, 0.82) or shade_hex(palette.selection_bg, 0.96)
      hl(0, "TelescopeNormal",          { bg = panel_bg, fg = palette.fg })
      hl(0, "TelescopeBorder",          { bg = panel_bg, fg = border_palette.border })
      hl(0, "TelescopePromptNormal",    { bg = panel_bg, fg = palette.fg })
      hl(0, "TelescopePromptBorder",    { bg = panel_bg, fg = border_palette.border })
      hl(0, "TelescopePromptTitle",     { bg = panel_bg, fg = palette.fg, bold = true })
      hl(0, "TelescopePromptPrefix",    { bg = panel_bg, fg = palette.muted, bold = true })
      hl(0, "TelescopePromptCounter",   { bg = panel_bg, fg = palette.muted })
      hl(0, "TelescopeResultsNormal",   { bg = panel_bg, fg = palette.fg })
      hl(0, "TelescopeResultsBorder",   { bg = panel_bg, fg = border_palette.border })
      hl(0, "TelescopeResultsTitle",    { bg = panel_bg, fg = palette.fg, bold = true })
      hl(0, "TelescopePreviewNormal",   { bg = panel_bg, fg = palette.fg })
      hl(0, "TelescopePreviewBorder",   { bg = panel_bg, fg = border_palette.border })
      hl(0, "TelescopePreviewTitle",    { bg = panel_bg, fg = palette.fg, bold = true })
      hl(0, "TelescopePreviewLine",     { bg = "NONE" })
      hl(0, "TelescopePreviewMatch",    { fg = palette.fg, bold = true })
      hl(0, "TelescopeSelection",       { bg = selection_bg, fg = palette.selection_fg, bold = true })
      hl(0, "TelescopeSelectionCaret",  { bg = selection_bg, fg = palette.fg, bold = true })
      hl(0, "TelescopeMatching",        { fg = palette.fg, bold = true })
      hl(0, "TelescopeMultiSelection",  { fg = palette.muted, bold = true })
    end

    apply_telescope_highlights()

    local tele_group = ui.create_augroup("TelescopeHighlights")
    ui.on_theme_change(tele_group, apply_telescope_highlights)
  end,
}
