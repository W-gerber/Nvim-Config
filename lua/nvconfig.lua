-- Minimal NvChad-config shim for base46 when used standalone.
--
-- base46 expects to find an `nvconfig` module; only the fields below are read.
-- The active theme is managed at runtime by lua/theme_switcher.lua, which
-- rewrites `base46.theme` before reloading highlights.

--- Load a per-theme override table, tolerating a missing file.
---
--- Cached, because `changed_themes` is read on every base46 highlight reload
--- and an uncached `require` of a missing module re-walks the whole
--- 'runtimepath' each time.
---@param name string module under lua/themes/
---@return table
local function overrides(name)
  local ok, module = pcall(require, "themes." .. name)
  return (ok and type(module) == "table") and module or {}
end

return {
  base46 = {
    theme = "neon_vommit",
    theme_toggle = { "neon_vommit", "default-light" },

    -- base46's own transparency is for themes designed see-through. The
    -- editor-wide "glass" look is a separate, user-toggleable setting that
    -- lives in lua/core/transparency.lua (`:Transparency`, <leader>ub).
    transparency = false,

    -- Extra base46 integrations to compile beyond its defaults.
    --
    -- Only plugins that are *not* already themed from lua/core/ui.lua belong
    -- here. Listing one that is (alpha, notify, rainbowdelimiters, todo) makes
    -- both systems write the same groups every switch — the manual pass wins,
    -- so base46's work is discarded, and the two drift apart silently.
    integrations = {
      "dap",
      "flash",
      "trouble",
    },

    -- base46 ships integrations for NvChad's own UI components. Exclude the
    -- ones this config replaces or doesn't use, so base46 doesn't fight the
    -- theme-derived highlights set from lua/core/ui.lua.
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

    -- Per-theme color overrides, merged into the theme tables (base_30/base_16)
    -- via base46.override_theme(). Works for built-in and custom themes alike.
    --
    -- Each entry points at a file under lua/themes/ holding just the keys you
    -- want to change; an empty one is a no-op, so they are safe to keep around
    -- as the place to reach for. Note `default-light` (the base46 theme id,
    -- with a hyphen) maps to `default_light.lua` (a legal Lua module name).
    changed_themes = {
      all = {},
      tokyonight = overrides("tokyonight"),
      ["default-light"] = overrides("default_light"),
    },
  },

  -- Minimal UI table to satisfy base46 integrations that expect NvChad config.
  ui = {
    cmp = {
      style = "default", -- default | atom | atom_colored | flat_light | flat_dark
    },
    telescope = {
      style = "borderless", -- borderless | bordered
    },
  },
}
