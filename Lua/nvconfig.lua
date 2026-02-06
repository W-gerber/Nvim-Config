return {
  -- Minimal config shim for NvChad's base46 when used standalone.
  base46 = {
    theme = "neon_commit",
    theme_toggle = { "neon_commit", "default-light" },
      -- Keep this false for "normal" solid-background themes.
      -- `theme_switcher` enables it only for `neon_commit`.
      transparency = false,

    -- Keep defaults; add custom integrations here if you want.
    integrations = {},
    -- base46 ships integrations for many NvChad components/plugins.
    -- Exclude ones you don't use (and ones that depend on NvChad's ui config).
    excluded = {
      "blink",
      "blankline",
      "nvcheatsheet",
      "nvimtree",
      "statusline",
      "tbline",
      "whichkey",
    },

    hl_override = {},
    hl_add = {},
    changed_themes = {
      -- Per-theme color overrides.
      -- These merge into the theme tables (base_30/base_16/etc) via base46.override_theme().
      -- Works for built-in themes (e.g. "tokyonight", "default-light") and your custom ones.
      --
      -- Example:
      -- tokyonight = {
      --   base_30 = {
      --     one_bg = "#10131a",
      --     pmenu_bg = "#10131a",
      --   },
      -- },
      all = {},

      -- Theme-specific override files you can edit:
      -- - Lua/themes/tokyonight.lua
      -- - Lua/themes/default_light.lua
      tokyonight = require("themes.tokyonight"),
      ["default-light"] = require("themes.default_light"),
    },
  },
    -- Minimal UI table to satisfy base46 integrations that expect NvChad config.
    ui = {
      cmp = {
        style = "default", -- supported: default|atom|atom_colored|flat_light|flat_dark
      },
      telescope = {
        style = "borderless", -- supported: borderless|bordered
      },
    },
}
