-- Flash: jump anywhere on screen in a couple of keystrokes.
--
-- The visual treatment is the part worth explaining. Flash's own defaults link
-- its groups to `Search`, `IncSearch` and `Substitute`, and most themes draw
-- those as a filled block — which is why an un-styled Flash looks like it is
-- boxing every match rather than pointing at it. The groups below replace that
-- with colored *text*: matches take a hue and a weight, the backdrop recedes,
-- and the only thing that keeps a solid background is the label itself, because
-- a single character overlaid on top of code has nothing else to make it
-- readable.
--
-- Colors come from `core.ui`'s palette and re-apply on theme change, like the
-- rest of the chrome.

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    label = {
      -- Rainbow labels give each jump target its own hue, which means the
      -- contrast against the code underneath is whatever that hue happens to
      -- land on. One high-contrast label color reads faster.
      rainbow = { enabled = false },

      -- Labels stay lowercase: a label you have to reach for shift to type is
      -- slower than the motion it replaced.
      uppercase = false,

      -- Overlay the label onto a cell that is already there instead of pushing
      -- the line sideways. Nothing reflows, so the code under the label stays
      -- where your eye already found it.
      style = "overlay",

      -- *Where* that overlay lands. These are positions, not an on/off pair:
      -- `after` puts a label on the cell just past the match, `before` one on
      -- the cell just before it, and either can be a `{ row, col }` offset
      -- instead of `true`. Setting both to `false` asks for a label in no
      -- position at all — flash still assigns the letters, then draws none of
      -- them, which from the outside looks exactly like "labels are broken".
      --
      -- One label, immediately after what you typed: press `s`, type two
      -- characters, and the third keystroke is sitting where you are already
      -- looking.
      after = true,
      before = false,
    },

    highlight = {
      -- Dim everything that isn't a match. This is what makes the labels
      -- findable at a glance; `FlashBackdrop` below keeps it gentle.
      backdrop = true,
      matches = true,
    },

    modes = {
      search = {
        enabled = true,
        -- `/` and `?` already highlight their own matches, and Flash dimming
        -- the whole buffer on every search is the most distracting thing it
        -- does by default.
        highlight = { backdrop = false },
      },

      char = {
        enabled = true,
        -- Same for `f`/`t`: these are small, local motions. Dimming the file to
        -- jump three characters is more disruptive than the jump.
        highlight = { backdrop = false },

        -- No labels on `f`/`t`. Repeating is clever-f instead: after `fx`,
        -- pressing `f` again goes to the next `x` and `F` back to the previous
        -- one, which is faster than reading a label for a motion this small.
        jump_labels = false,

        -- `;` and `,` are deliberately absent from this list (flash's default
        -- includes them). They belong to the Treesitter motions — `]f`, `]C`,
        -- `]a` in plugins/treesitter.lua — which have no other way to repeat,
        -- whereas character motions already repeat through clever-f above.
        --
        -- Spelled out rather than left to chance: flash only skips `;`/`,` when
        -- something has *already* mapped them, so with both plugins claiming
        -- the keys the winner would be whichever happened to load second.
        keys = { "f", "F", "t", "T" },
      },

      treesitter = {
        -- Selecting a syntax node *is* a "which of these" question, so the
        -- labels earn the backdrop here.
        highlight = { backdrop = true, matches = false },
      },
    },
  },
  keys = {
    {
      "s",
      mode = { "n", "x", "o" },
      function() require("flash").jump() end,
      desc = "Flash: Jump",
    },
    {
      "S",
      mode = { "n", "x", "o" },
      function() require("flash").treesitter() end,
      desc = "Flash: Treesitter",
    },
    {
      "r",
      mode = "o",
      function() require("flash").remote() end,
      desc = "Flash: Remote",
    },
    {
      "R",
      mode = { "o", "x" },
      function() require("flash").treesitter_search() end,
      desc = "Flash: Treesitter Search",
    },
    {
      "<c-s>",
      mode = { "c" },
      function() require("flash").toggle() end,
      desc = "Flash: Toggle (cmdline)",
    },
  },
  config = function(_, opts)
    local ui = require("core.ui")

    require("flash").setup(opts)

    local function apply_flash_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl

      -- The backdrop is a foreground change only — no background, so a
      -- transparent terminal stays transparent while Flash is active. Pulled
      -- roughly halfway to the background: enough that matches pop, not so far
      -- that you lose the shape of the code you are aiming at.
      hl(0, "FlashBackdrop", { fg = ui.blend(p.muted, p.bg, 0.5), bg = "NONE" })

      -- Matches: the text itself takes the color. `bg = "NONE"` is what removes
      -- the block that `Search` would otherwise have drawn.
      hl(0, "FlashMatch", { fg = p.cyan, bg = "NONE", bold = true })

      -- The match the cursor would land on if you stopped typing now. A
      -- different hue plus an underline, so it is distinguishable from its
      -- neighbours without a fill.
      hl(0, "FlashCurrent", { fg = p.orange, bg = "NONE", bold = true, underline = true })

      -- The one thing that keeps a solid background. A label is a single
      -- character sitting on top of unrelated code; without a fill behind it
      -- there is no reliable contrast, and misreading a label costs a jump.
      -- `ui.contrast()` picks black or white against whatever the theme's
      -- accent is, so this stays legible on light themes too.
      local label_bg = p.glow and p.glow_accent or p.pink
      hl(0, "FlashLabel", {
        fg = ui.contrast(label_bg),
        bg = label_bg,
        bold = true,
        -- No italics: at one character wide, a slanted glyph is just blur.
        italic = false,
      })

      -- The `/`-style prompt Flash opens for its search and remote modes.
      hl(0, "FlashPrompt", { fg = p.fg, bg = ui.pane_bg(0.1) })
      hl(0, "FlashPromptIcon", { fg = p.accent, bg = ui.pane_bg(0.1) })
      hl(0, "FlashCursor", { fg = ui.contrast(p.accent), bg = p.accent })
    end

    apply_flash_highlights()
    ui.on_theme_change(ui.create_augroup("FlashHighlights"), apply_flash_highlights)
  end,
}
