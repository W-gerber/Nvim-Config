return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  opts = {
    -- Used as the color for 100% transparency. Fixes:
    -- "Highlight group 'NotifyBackground' has no background highlight"
    background_colour = "#000000",
    timeout = 2500,
    stages = "fade",
    max_height = function()
      return math.floor(vim.o.lines * 0.75)
    end,
    max_width = function()
      return math.floor(vim.o.columns * 0.75)
    end,
  },
  config = function(_, opts)
    local ok, notify = pcall(require, "notify")
    if not ok then
      return
    end
    notify.setup(opts)
    vim.notify = notify
  end,
}
