return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  opts = function()
    local palette = require("core.ui").float_palette()

    return {
      background_colour = palette.bg,
      timeout = 2500,
      stages = "fade",
      render = "wrapped-compact",
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
    }
  end,
  config = function(_, opts)
    local ok, notify = pcall(require, "notify")
    if not ok then
      return
    end

    local ui = require("core.ui")

    local function apply_notify_highlights()
      local palette = ui.float_palette()
      local hl = vim.api.nvim_set_hl
      local levels = {
        ERROR = palette.error,
        WARN = palette.warning,
        INFO = palette.accent,
        DEBUG = palette.muted,
        TRACE = palette.secondary,
      }

      hl(0, "NotifyBackground", { bg = palette.bg })

      for level, color in pairs(levels) do
        hl(0, "Notify" .. level .. "Border", { fg = color, bg = palette.bg })
        hl(0, "Notify" .. level .. "Icon", { fg = color, bg = palette.bg })
        hl(0, "Notify" .. level .. "Title", { fg = color, bg = palette.bg, bold = true })
        hl(0, "Notify" .. level .. "Body", { fg = palette.fg, bg = palette.bg })
      end
    end

    opts.background_colour = ui.float_palette().bg
    apply_notify_highlights()
    local notify_group = ui.create_augroup("NotifyThemeHighlights")
    ui.on_theme_change(notify_group, apply_notify_highlights)

    notify.setup(opts)
    vim.notify = notify
  end,
}
