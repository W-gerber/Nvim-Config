return {
  -- Auto-pairing for brackets, quotes, and other delimiters: typing `(` inserts
  -- the closing `)`, and Treesitter is consulted so it doesn't fire inside
  -- strings or comments.
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local ok, autopairs = pcall(require, "nvim-autopairs")
    if not ok then
      return
    end

    autopairs.setup({
      check_ts = true, -- ask Treesitter whether a pair makes sense here
      ts_config = {
        lua = { "string" }, -- no pairs inside Lua string nodes
        javascript = { "template_string" },
        java = false, -- Java's TS pairing is heavy; keep it off for responsiveness
      },
      -- Prompts and UI buffers should never auto-pair.
      disable_filetype = { "TelescopePrompt", "vim", "alpha", "neo-tree" },
      fast_wrap = {
        -- Wrap the text after the cursor in the delimiter you pick.
        --
        -- <M-e> is the only binding on purpose: nvim-cmp owns <C-e> (abort
        -- completion), and mapping both meant whichever plugin's config ran
        -- last silently won. If your terminal swallows Alt, rebind here rather
        -- than adding a second mapping.
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

    -- Insert `(` automatically after confirming a function/method from cmp.
    local ok_cmp, cmp = pcall(require, "cmp")
    if ok_cmp then
      local ok_bridge, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
      if ok_bridge then
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end
  end,
}
