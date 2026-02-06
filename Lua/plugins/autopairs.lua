return {
  -- Auto-pairing for brackets, quotes, and other delimiters.
  -- Automatically inserts closing ), }, ], ", ', etc. when you type the opening one.
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local ok, autopairs = pcall(require, "nvim-autopairs")
    if not ok then
      return
    end

    autopairs.setup({
      check_ts = true, -- Use Treesitter to check pairs
      ts_config = {
        lua = { "string" }, -- Don't add pairs in lua string treesitter nodes
        javascript = { "template_string" },
        java = false, -- Java TS pairing can be heavy; keep it off for responsiveness.
      },
      -- Avoid pairing in prompts/UI buffers
      disable_filetype = { "TelescopePrompt", "vim", "alpha", "neo-tree" },
      fast_wrap = {
        -- Fast wrap: wrap the nearest text with (), {}, [], quotes, etc.
        -- Note: some terminals swallow Alt combos; we also provide <C-e>.
        map = "<M-e>",
        chars = { "{", "[", "(", '"', "'" },
        pattern = [=[[%'%"%>%]%)%}%,]]=],
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "Search",
        highlight_grey = "Comment",
      },
    })

    -- Alternate fast-wrap mapping (more reliable in Windows terminals)
    pcall(function()
      local wr = require("nvim-autopairs.fastwrap")
      vim.keymap.set("i", "<C-e>", function()
        wr.show()
      end, { desc = "Autopairs: Fast wrap", silent = true })
    end)

    -- Integration with nvim-cmp: auto-insert `(` after selecting a function/method
    local ok_cmp, cmp = pcall(require, "cmp")
    if ok_cmp then
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
  end,
}
