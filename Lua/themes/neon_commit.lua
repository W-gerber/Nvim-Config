local M = {}

-- Neon-commit (custom)
-- Palette derived from your current theme.lua
M.base_30 = {
  white = "#ffffff",
  darker_black = "#000000",
  black = "#000000",
  black2 = "#080808",
  one_bg = "#080808",
  one_bg2 = "#101010",
  one_bg3 = "#141414",
  grey = "#303030",
  grey_fg = "#808080",
  grey_fg2 = "#808080",
  light_grey = "#808080",
  red = "#ff2d95",
  baby_pink = "#ff2d95",
  pink = "#ff2d95",
  line = "#303030",
  green = "#b7ff3a",
  vibrant_green = "#b7ff3a",
  nord_blue = "#00d7ff",
  blue = "#00d7ff",
  yellow = "#CFFF04",
  sun = "#CFFF04",
  purple = "#9d7cff",
  dark_purple = "#9d7cff",
  teal = "#1e90ff",
  orange = "#ff9e1b",
  cyan = "#00d7ff",
  statusline_bg = "#000000",
  lightbg = "#101010",
  pmenu_bg = "#9d7cff",
  folder_bg = "#00d7ff",
}

M.base_16 = {
  base00 = "#000000",
  base01 = "#080808",
  base02 = "#101010",
  base03 = "#303030",
  base04 = "#808080",
  base05 = "#ffffff",
  base06 = "#d6afff",
  base07 = "#ffffff",
  base08 = "#ff2d95",
  base09 = "#ff9e1b",
  base0A = "#CFFF04",
  base0B = "#b7ff3a",
  base0C = "#1e90ff",
  base0D = "#00d7ff",
  base0E = "#9d7cff",
  base0F = "#d6afff",
}

M.type = "dark"

local ok_base46, base46 = pcall(require, "base46")
if ok_base46 then
  M = base46.override_theme(M, "neon_commit")
end

return M
