local M = {}

local ok_pickers, pickers = pcall(require, "telescope.pickers")
if not ok_pickers then
  return M
end

local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")
local entry_display = require("telescope.pickers.entry_display")

local strings = require("plenary.strings")

local SWATCH_COUNT = 8
local SWATCH_CHAR = "●"

local function sanitize_id(id) return (id:gsub("[^%w_]", "_")) end

local function ensure_swatch_hls(theme)
  if not theme or type(theme.palette) ~= "table" then
    return
  end

  local sid = sanitize_id(theme.id or "")

  -- Icon highlight using theme's primary color
  local primary = theme.palette[1] or "#ffffff"
  vim.api.nvim_set_hl(0, string.format("ThemePickerIcon_%s", sid), { fg = primary, bold = true })

  -- Swatch highlights
  for idx = 1, SWATCH_COUNT do
    local color = theme.palette[idx]
    if type(color) == "string" and color:match("^#%x%x%x%x%x%x$") then
      local group = string.format("ThemePickerSwatch_%s_%d", sid, idx)
      vim.api.nvim_set_hl(0, group, { fg = color })
    end
  end
end

local function make_displayer(name_width)
  local items = {
    { width = 1 }, -- Icon
    { width = 1 }, -- Spacer
    { width = name_width + 2 }, -- Theme name
  }
  for _ = 1, SWATCH_COUNT do
    table.insert(items, { width = 2 })
  end

  return entry_display.create({
    separator = " ",
    items = items,
  })
end

local function get_theme_list()
  local ok, theme_mod = pcall(require, "theme_switcher.themes")
  if ok and theme_mod and type(theme_mod.get_all) == "function" then
    return theme_mod.get_all()
  end
  return {}
end

-- This file used to re-link TelescopeNormal/Border/Selection to the built-in
-- float groups on open and restore them on close. That had no lasting effect:
-- every preview below switches the theme, which fires `User ThemeSwitched`, and
-- plugins/telescope.lua's handler writes those same groups explicitly — so the
-- links were gone by the second arrow key. The picker now simply looks like
-- every other picker in the config, which is what the rest of it is for.

function M.open(opts)
  opts = opts or {}

  local theme_switcher = require("theme_switcher")
  local current_id = theme_switcher.current_id()
  local original_id = current_id

  local all_themes = get_theme_list()

  -- Display sizing: match screenshot aesthetic
  local max_name = 0
  for _, t in ipairs(all_themes) do
    max_name = math.max(max_name, strings.strdisplaywidth(t.name or t.id or ""))
  end
  local name_width = math.max(14, math.min(20, max_name + 2))
  local displayer = make_displayer(name_width)

  local function preview(theme_id)
    if not theme_id or theme_id == current_id then
      return
    end
    current_id = theme_id
    theme_switcher.apply(theme_id, { persist = false, preview = true })
  end

  -- Debounce preview to avoid flashing on rapid selection movement.
  local pending = 0
  local function preview_debounced(theme_id)
    pending = pending + 1
    local token = pending
    vim.defer_fn(function()
      if token ~= pending then
        return
      end
      preview(theme_id)
    end, 30)
  end

  local function revert()
    if original_id and current_id ~= original_id then
      theme_switcher.apply(original_id, { persist = false, preview = true })
      current_id = original_id
    end
  end

  local function apply_and_persist(theme_id)
    if not theme_id then
      return
    end
    current_id = theme_id
    theme_switcher.apply(theme_id, { persist = true, preview = false })
  end

  local dropdown_opts = themes.get_dropdown({
    prompt_title = "Themes",
    results_title = false,
    previewer = false,
    sorting_strategy = "ascending",
    initial_mode = "insert",
    selection_caret = "▸ ",
    prompt_prefix = "Filter: ",
    entry_prefix = "  ",
    winblend = 0,
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    layout_config = {
      width = function(_, max_columns)
        return math.min(max_columns, math.max(60, math.floor(max_columns * 0.55)))
      end,
      height = function(_, _, max_lines)
        return math.min(max_lines, math.max(14, math.min(22, #all_themes + 4)))
      end,
      prompt_position = "top",
    },
  })

  pickers
    .new(dropdown_opts, {
      finder = finders.new_table({
        results = all_themes,
        entry_maker = function(theme)
          ensure_swatch_hls(theme)
          local sid = sanitize_id(theme.id)
          local icon_hl = string.format("ThemePickerIcon_%s", sid)

          return {
            value = theme.id,
            ordinal = (theme.name .. " " .. theme.id):lower(),
            display = function()
              local cols = {}
              cols[1] = { "󰏘", icon_hl } -- Palette icon
              cols[2] = "" -- Spacer
              cols[3] = theme.name
              for i = 1, SWATCH_COUNT do
                local group = string.format("ThemePickerSwatch_%s_%d", sid, i)
                cols[i + 3] = { SWATCH_CHAR, group }
              end
              return displayer(cols)
            end,
          }
        end,
      }),

      sorter = sorters.get_fzy_sorter(),

      attach_mappings = function(bufnr, map)
        local function get_selected_id()
          local entry = action_state.get_selected_entry()
          return entry and entry.value or nil
        end

        actions.select_default:replace(function()
          local id = get_selected_id()
          actions.close(bufnr)
          apply_and_persist(id)
        end)

        local function close_without_save()
          actions.close(bufnr)
          revert()
        end

        map("i", "<Esc>", close_without_save)
        map("n", "q", close_without_save)
        map("n", "<Esc>", close_without_save)

        local function move_and_preview(next_fn)
          return function()
            next_fn(bufnr)
            local id = get_selected_id()
            if id then
              preview_debounced(id)
            end
          end
        end

        map("i", "<Down>", move_and_preview(actions.move_selection_next))
        map("i", "<Up>", move_and_preview(actions.move_selection_previous))
        map("n", "j", move_and_preview(actions.move_selection_next))
        map("n", "k", move_and_preview(actions.move_selection_previous))

        -- First open: preview the current selection row immediately.
        vim.schedule(function()
          local id = get_selected_id()
          if id then
            preview_debounced(id)
          end
        end)

        return true
      end,
    })
    :find()
end

return M
