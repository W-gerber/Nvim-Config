-- Theme registry used by the picker (<leader>th) and the :Theme command.
--
-- Each entry describes one selectable theme:
--
--   id          base46 theme id — the module name under lua/themes/, and the
--               name tried with :colorscheme
--   name        display name in the picker
--   palette     up to 8 hex colors, shown as swatches in the picker
--   kind        "colorscheme" for ordinary colorscheme plugins (non-base46);
--               omitted for base46 themes
--   background  "dark" (default) or "light" — set *before* the theme loads so
--               variants that follow 'background' (catppuccin, onedarkpro, ...)
--               don't inherit whatever the previous theme left behind
--   glass       default state of the see-through "glass" background for this
--               theme. Themes whose identity depends on their own backdrop
--               (synthwave84) opt out; an explicit <leader>ub choice always
--               wins over this hint.

local M = {}

M.themes = {
  {
    id = "neon_vommit",
    name = "neon vommit",
    glass = false,
    palette = { "#ff00aa", "#76ee00", "#66d9ef", "#cbc3ff", "#33cc99", "#ffff00", "#cc33ff", "#fd971f" },
  },
  {
    id = "synthwave84",
    name = "synthwave '84",
    glass = false,
    palette = { "#ff7edb", "#36f9f6", "#fede5d", "#f97e72", "#72f1b8", "#fe4450", "#ff8b39", "#b893ce" },
  },
  {
    id = "neon_commit",
    name = "neon commit",
    glass = true,
    palette = { "#00d7ff", "#ff2d95", "#b7ff3a", "#9d7cff", "#ff9e1b", "#CFFF04", "#1e90ff", "#d6afff" },
  },
  {
    id = "tokyonight",
    name = "tokyonight",
    palette = { "#7aa2f7", "#bb9af7", "#9ece6a", "#f7768e", "#e0af68", "#2ac3de", "#7dcfff", "#c0caf5" },
  },
  {
    id = "dracula",
    name = "dracula",
    palette = { "#bd93f9", "#ff79c6", "#50fa7b", "#8be9fd", "#f1fa8c", "#ff5555", "#6272a4", "#f8f8f2" },
  },
  {
    id = "default-light",
    name = "default light",
    background = "light",
    glass = false,
    palette = { "#ffffff", "#f6f6f6", "#e5e7eb", "#9ca3af", "#6b7280", "#111827", "#2563eb", "#16a34a" },
  },

  -- External (non-base46) colorschemes ---------------------------------------
  {
    id = "catppuccin",
    name = "catppuccin",
    kind = "colorscheme",
    palette = { "#f5c2e7", "#cba6f7", "#89b4fa", "#a6e3a1", "#f9e2af", "#fab387", "#f38ba8", "#cdd6f4" },
  },
  {
    id = "onedark",
    name = "onedarkpro",
    kind = "colorscheme",
    palette = { "#61afef", "#c678dd", "#98c379", "#e5c07b", "#e06c75", "#56b6c2", "#abb2bf", "#282c34" },
  },
  {
    id = "evergarden",
    name = "evergarden",
    kind = "colorscheme",
    palette = { "#97c9c3", "#dbbc7f", "#e69875", "#e67e80", "#dcaed7", "#7fbbb3", "#d3c6aa", "#313b40" },
  },
  {
    id = "bamboo",
    name = "bamboo",
    kind = "colorscheme",
    palette = { "#a7c080", "#dbbc7f", "#e69875", "#e67e80", "#7fbbb3", "#d3c6aa", "#859289", "#272e33" },
  },
  {
    id = "yorumi",
    name = "yorumi",
    kind = "colorscheme",
    palette = { "#7aa2f7", "#bb9af7", "#9ece6a", "#f7768e", "#e0af68", "#2ac3de", "#c0caf5", "#1a1b26" },
  },
  {
    id = "lavi",
    name = "lavi",
    kind = "colorscheme",
    palette = { "#d7c4ff", "#bca3ff", "#9bbcff", "#a1e8af", "#ffd29d", "#ff9fba", "#9be3ff", "#f2eaff" },
  },
}

--- Every registered theme, in picker order.
---@return table[]
function M.get_all() return M.themes end

--- Look up a theme definition by id.
---@param theme_id string
---@return table|nil
function M.get_by_id(theme_id)
  for _, theme in ipairs(M.themes) do
    if theme.id == theme_id then
      return theme
    end
  end
end

return M
