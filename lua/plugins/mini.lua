-- mini.nvim modules.
--
-- Installed one module at a time (`echasnovski/mini.<name>`) rather than as the
-- mini.nvim bundle: the bundle pulls in forty-odd modules to use two, and each
-- one is a separate spec lazy.nvim can load on its own trigger.
--
-- mini.pairs is deliberately *not* here. nvim-autopairs (plugins/autopairs.lua)
-- already does the same job, and does it with two things mini.pairs has no
-- equivalent for in this config: `check_ts`, so a `(` inside a string or a
-- comment doesn't get a partner, and the `confirm_done` bridge that appends the
-- call parens when you accept a function from nvim-cmp. Running both would mean
-- two plugins racing to insert the same closing bracket.

return {
  -- -------------------------------------------------------------------------
  -- Icons
  -- -------------------------------------------------------------------------
  --
  -- A single icon provider for filetypes, LSP kinds, directories and more. It
  -- knows about things nvim-web-devicons has no concept of (LSP symbol kinds,
  -- option names), and it resolves by content as well as by extension.
  --
  -- `mock_nvim_web_devicons()` makes it answer to `require("nvim-web-devicons")`
  -- too, so Neo-tree, Telescope and lualine keep working through the API they
  -- already call — no duplicate icon tables, one place to change a glyph.
  {
    "echasnovski/mini.icons",
    lazy = true,
    opts = {
      style = "glyph",

      -- Filetypes this config cares about that mini doesn't have a strong
      -- default for, or where a clearer glyph exists.
      file = {
        [".keep"] = { glyph = "\u{f0224}", hl = "MiniIconsGrey" },
        ["init.lua"] = { glyph = "\u{e620}", hl = "MiniIconsAzure" },
        ["lazy-lock.json"] = { glyph = "\u{f0770}", hl = "MiniIconsBlue" },
        ["nvconfig.lua"] = { glyph = "\u{e620}", hl = "MiniIconsAzure" },
      },
      filetype = {
        dotenv = { glyph = "\u{f0ad}", hl = "MiniIconsYellow" },
      },
    },
    init = function()
      -- `package.preload` is consulted before every other module searcher,
      -- including lazy.nvim's, so this intercepts the first `require` of
      -- nvim-web-devicons from anywhere — Neo-tree's dependency list included —
      -- and loads mini.icons at that moment instead of at startup.
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  -- -------------------------------------------------------------------------
  -- Surround
  -- -------------------------------------------------------------------------
  --
  -- Add, delete and replace surrounding pairs: `gsaiw"` quotes a word,
  -- `gsd"` unquotes it, `gsr"'` swaps double for single.
  --
  -- The `gs` prefix rather than mini's default bare `s` is not a preference:
  -- `s` is Flash's jump key in normal, visual and operator-pending mode (see
  -- plugins/flash.lua). Leaving the default would mean every `s` waited out
  -- 'timeoutlen' to find out whether a surround command was coming.
  {
    "echasnovski/mini.surround",
    keys = {
      { "gsa", mode = { "n", "v" }, desc = "Surround: add" },
      { "gsd", desc = "Surround: delete" },
      { "gsr", desc = "Surround: replace" },
      { "gsf", desc = "Surround: find right" },
      { "gsF", desc = "Surround: find left" },
      { "gsh", desc = "Surround: highlight" },
      { "gsn", desc = "Surround: update n_lines" },
    },
    opts = {
      mappings = {
        add = "gsa",
        delete = "gsd",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "gsr",
        update_n_lines = "gsn",

        -- Off: these are only bound inside an active surround prompt, and the
        -- defaults shadow `[`/`]` bracket motions there.
        suffix_last = "",
        suffix_next = "",
      },

      -- How far to look for the other half of a pair. The default (20) gives up
      -- inside a JSX block or a long function signature.
      n_lines = 60,

      -- Briefly flash what `gsh` matched, long enough to read.
      highlight_duration = 400,

      search_method = "cover_or_next",
    },
  },
}
