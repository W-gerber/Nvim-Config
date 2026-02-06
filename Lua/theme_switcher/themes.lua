local M = {}

-- Theme definitions used by the theme picker.
-- Each theme has:
--   - id: the base46 theme id (and attempted :colorscheme name)
--   - name: display name
--   - palette: array of hex colors (up to 8) for swatches
M.themes = {
  {
    id = "neon_commit",
    name = "neon_commit",
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
    name = "default-light",
    palette = { "#ffffff", "#f6f6f6", "#e5e7eb", "#9ca3af", "#6b7280", "#111827", "#2563eb", "#16a34a" },
  },

  -- External (non-base46) colorschemes
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

function M.get_all()
  return M.themes
end

function M.get_by_id(theme_id)
  for _, t in ipairs(M.themes) do
    if t.id == theme_id then
      return t
    end
  end
  return nil
end

return M
