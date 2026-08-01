-- Vimade: dim every window except the one you are in.
--
-- The point is peripheral: with four splits open, the one that has focus should
-- be obvious without reading the cursor position. Vimade fades the *text* of
-- inactive windows toward the background rather than tinting their background,
-- which is what keeps it working over a transparent terminal — a background
-- tint would paint over the thing transparency exists to show.
--
-- `ncmode = "windows"` is the setting that makes this do what you'd expect.
-- Vimade's default ("buffers") only fades windows showing a *different* buffer,
-- so two splits on the same file stay equally bright.

return {
  "tadaa/vimade",
  event = { "WinNew", "WinEnter" },
  cmd = { "VimadeEnable", "VimadeDisable", "VimadeToggle", "VimadeFocus", "VimadeUnfocus" },
  keys = {
    { "<leader>uv", "<cmd>VimadeToggle<cr>", desc = "Toggle window dimming" },
  },
  opts = {
    -- Minimalist fades text only, leaving highlights, signs and the cursorline
    -- alone. The heavier recipes also fade those, which on a transparent
    -- terminal reads as the inactive window having a different theme.
    recipe = { "minimalist", { animate = true } },

    -- 0.0 is invisible, 1.0 is untouched. 0.6 is enough to tell the windows
    -- apart at a glance while leaving the inactive ones readable.
    fadelevel = 0.6,
    animate = true,

    -- Fade all inactive windows, not just ones holding another buffer.
    ncmode = "windows",

    blocklist = {
      -- Vimade's own defaults: the statusline under laststatus=3, the tabline's
      -- selected entry, and the popup menu. Repeated here because supplying a
      -- `blocklist` replaces the table rather than merging into it.
      default = {
        highlights = {
          laststatus_3 = function()
            if vim.go.laststatus == 3 then
              return "StatusLine"
            end
          end,
          "TabLineSel",
          "Pmenu",
          "PmenuSel",
          "PmenuKind",
          "PmenuKindSel",
          "PmenuExtra",
          "PmenuExtraSel",
          "PmenuSbar",
          "PmenuThumb",
        },
        buf_opts = { buftype = { "prompt" } },
      },

      -- Floats are already visually separate and are usually the thing you are
      -- looking at; fading the one behind a picker just makes the preview hard
      -- to read. Terminal floats stay faded when they don't have focus.
      default_block_floats = function(win, active)
        return win.win_config.relative ~= ""
          and (win ~= active or win.buf_opts.buftype == "terminal")
          and true
          or false
      end,

      -- Chrome that is meant to be legible while you work elsewhere: the file
      -- tree is a navigation aid, and the dashboard is the whole screen.
      chrome = { buf_opts = { filetype = { "neo-tree", "alpha", "notify" } } },
    },
  },
}
