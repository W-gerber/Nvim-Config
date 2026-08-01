-- Central icon table (Nerd Font v3).
--
-- Glyphs are written as `\u{...}` escapes on purpose: the raw characters live in
-- the Unicode private-use area, and plenty of tools (diff viewers, editors,
-- clipboards, AI assistants) silently drop them, which leaves blank icons behind.
-- Escapes survive all of that and are greppable.
--
-- Requires a Nerd Font in the terminal: https://www.nerdfonts.com

return {
  -- Diagnostics (sign column, statusline, Trouble)
  diagnostics = {
    error = "\u{f057}", -- nf-fa-times_circle
    warn = "\u{f071}", -- nf-fa-exclamation_triangle
    info = "\u{f05a}", -- nf-fa-info_circle
    hint = "\u{f0335}", -- nf-md-lightbulb_on
  },

  -- Git / diff
  git = {
    branch = "\u{e0a0}", -- powerline branch
    added = "\u{f067}", -- plus
    modified = "\u{f444}", -- filled dot
    removed = "\u{f068}", -- minus
    renamed = "\u{f554}",
    untracked = "\u{f128}",
    ignored = "\u{f474}",
  },

  -- Files / buffers
  file = {
    modified = "\u{25cf}", -- ●
    readonly = "\u{f023}", -- lock
    new = "\u{f016}", -- file outline
    folder = "\u{e5ff}", -- closed folder
    folder_open = "\u{e5fe}",
    folder_empty = "\u{f414}",
  },

  -- Chrome / decorations
  ui = {
    pill_left = "\u{e0b6}", -- ◖ rounded left edge
    pill_right = "\u{e0b4}", -- ◗ rounded right edge
    ellipsis = "\u{2026}", -- …
    clock = "\u{f017}",
    home = "\u{f015}",
    search = "\u{f0349}",
    caret = "\u{258e}", -- ▎
    chevron_right = "\u{f0142}",
    chevron_down = "\u{f0140}",
    separator = "\u{2502}", -- │
  },

  -- Debugger (plugins/dap.lua)
  dap = {
    breakpoint = "\u{f0403}", -- filled circle
    breakpoint_conditional = "\u{f0405}",
    breakpoint_rejected = "\u{f0748}",
    log_point = "\u{f0629}",
    stopped = "\u{f04b}", -- play
  },

  -- Media (core/music.lua)
  music = {
    playing = "\u{f0386}", -- music note
    paused = "\u{f03e4}", -- pause
    stopped = "\u{f04db}", -- stop
  },
}
