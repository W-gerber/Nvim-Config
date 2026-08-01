-- neon_commit — the custom base46 theme this config ships with.
--
-- The accent colors come from Lua/theme.lua so the brand palette is defined in
-- exactly one place; the greys below are theme-local scaffolding.

local neon = require("theme").neon

local ink = {
  black = "#000000",
  near_black = neon.bg, -- #080808
  raised = "#101010",
  raised_alt = "#141414",
  line = "#303030",
  grey = neon.gray, -- #808080
}

local M = {}

M.base_30 = {
  white = neon.white,
  darker_black = ink.black,
  black = ink.black,
  black2 = ink.near_black,
  one_bg = ink.near_black,
  one_bg2 = ink.raised,
  one_bg3 = ink.raised_alt,
  grey = ink.line,
  grey_fg = ink.grey,
  grey_fg2 = ink.grey,
  light_grey = ink.grey,
  red = neon.hotpink,
  baby_pink = neon.hotpink,
  pink = neon.hotpink,
  line = ink.line,
  green = neon.lime,
  vibrant_green = neon.lime,
  nord_blue = neon.cyan,
  blue = neon.cyan,
  yellow = neon.neon_yellow,
  sun = neon.neon_yellow,
  purple = neon.purple,
  dark_purple = neon.purple,
  teal = neon.blue,
  orange = neon.orange,
  cyan = neon.cyan,
  statusline_bg = ink.black,
  lightbg = ink.raised,
  pmenu_bg = neon.purple,
  folder_bg = neon.cyan,
}

M.base_16 = {
  base00 = ink.black,
  base01 = ink.near_black,
  base02 = ink.raised,
  base03 = ink.line,
  base04 = ink.grey,
  base05 = neon.white,
  base06 = neon.light_purple,
  base07 = neon.white,
  base08 = neon.hotpink,
  base09 = neon.orange,
  base0A = neon.neon_yellow,
  base0B = neon.lime,
  base0C = neon.blue,
  base0D = neon.cyan,
  base0E = neon.purple,
  base0F = neon.light_purple,
}

M.type = "dark"

local ok_base46, base46 = pcall(require, "base46")
if ok_base46 then
  M = base46.override_theme(M, "neon_commit")
end

return M
