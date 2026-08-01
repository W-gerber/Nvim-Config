return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  opts = {
    timeout = 2500,
    render = "wrapped-compact",
    fps = 30,
    top_down = false, -- notifications rise from the bottom, away from the tabline
    max_height = function() return math.floor(vim.o.lines * 0.75) end,
    max_width = function() return math.floor(vim.o.columns * 0.75) end,
  },
  config = function(_, opts)
    local ok, notify = pcall(require, "notify")
    if not ok then
      return
    end

    local ui = require("core.ui")

    local function apply_notify_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl

      -- Transparent while the glass preference is on, so toasts are text over
      -- the terminal's own backdrop; a neutral frost otherwise.
      local surface = ui.pane_bg(0.1)
      local on_surface = ui.contrast(ui.frost(0.1), p.bg, p.fg)

      local levels = {
        ERROR = p.red,
        WARN = p.yellow,
        INFO = p.accent,
        DEBUG = p.muted,
        TRACE = p.purple,
      }

      hl(0, "NotifyBackground", { bg = surface })

      for level, color in pairs(levels) do
        hl(0, "Notify" .. level .. "Border", { fg = color, bg = surface })
        hl(0, "Notify" .. level .. "Icon", { fg = color, bg = surface })
        hl(0, "Notify" .. level .. "Title", { fg = color, bg = surface, bold = true })
        hl(0, "Notify" .. level .. "Body", { fg = on_surface, bg = surface })
      end
    end

    --- Animation and blend color, both of which depend on transparency.
    ---
    --- The fade stages work by ramping `winblend`, which composites the toast
    --- against whatever is beneath it — over a transparent editor that resolves
    --- to the default background, i.e. a dark box on top of the terminal's own
    --- blur. `static` skips the blending entirely and lets the backdrop through.
    --- nvim-notify still wants a concrete `background_colour` either way: given
    --- a transparent one it warns and falls back to black.
    local function animation()
      return {
        stages = vim.g.ui_transparent and "static" or "fade",
        background_colour = ui.frost(0.1),
      }
    end

    apply_notify_highlights()
    ui.on_theme_change(ui.create_augroup("NotifyThemeHighlights"), function()
      apply_notify_highlights()
      pcall(notify.setup, vim.tbl_extend("force", opts, animation()))
    end)

    notify.setup(vim.tbl_extend("force", opts, animation()))
    vim.notify = notify
  end,
}
