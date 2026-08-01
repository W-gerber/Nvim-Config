return {
  "NvChad/base46",
  lazy = false,
  priority = 1000,
  config = function()
    -- base46 uses this cache path for compiled highlights
    vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
  end,
}
