-- Dashboard (alpha-nvim), in two switchable styles:
--
--   intro    a faithful copy of Neovim's own startup screen — same logo, same
--            lines, same highlight rules, so it reads like `nvim --clean`
--   classic  the block-letter logo this config used before, above the action
--            buttons (find file, recent files, sessions, ...)
--
-- `:Dashboard [intro|classic]` switches between them and `<leader>ua` toggles.
-- The choice is persisted in core.state, next to the theme and glass settings.

local DEFAULT_STYLE = "intro"
local STYLES = { "intro", "classic" }

-- ---------------------------------------------------------------------------
-- Style "intro": Neovim's own startup screen
-- ---------------------------------------------------------------------------
--
-- Transcribed from `intro_message()` in src/nvim/version.c. Neovim paints that
-- screen straight onto the grid rather than into a buffer, so there is nothing
-- for alpha to reuse — the lines and their highlights have to be rebuilt here.

local INTRO_LOGO = {
  "│ ╲ ││",
  "││╲╲││",
  "││ ╲ │",
}

-- Every non-logo line in the real intro is 44 columns wide at most, and the
-- rules are exactly that wide.
local INTRO_RULE = string.rep("─", 44)

-- Named groups rather than direct links so a theme can restyle the intro on its
-- own; `apply_highlights()` links them to the groups Neovim itself uses.
local INTRO_HL = {
  logo = "AlphaIntroLogo", -- up to the diagonal
  logo_alt = "AlphaIntroLogoAlt", -- from the diagonal on
  version = "AlphaIntroVersion",
  rule = "AlphaIntroRule",
  key = "AlphaIntroKey", -- ":" and "<Enter>"
  command = "AlphaIntroCommand",
}

--- The version string Neovim prints in its intro (`NVIM_VERSION_LONG`).
---
--- Taken from `:version` itself, whose first line *is* that string — building
--- it from `vim.version()` would drop the "-dev" suffix on nightly builds.
---@return string
local function version_line()
  local ok, result = pcall(vim.api.nvim_exec2, "version", { output = true })
  local first = ok and type(result.output) == "string" and result.output:match("^[^\r\n]+")

  if first and vim.startswith(first, "NVIM") then
    return first
  end

  local v = vim.version()
  return string.format("NVIM v%d.%d.%d", v.major, v.minor, v.patch)
end

--- The intro screen's lines, in order.
---@return string[]
local function intro_lines()
  local v = vim.version()

  local lines = vim.list_extend({}, INTRO_LOGO)

  return vim.list_extend(lines, {
    "",
    version_line(),
    INTRO_RULE,
    "Nvim is open source and freely distributable",
    "https://neovim.io/#chat",
    INTRO_RULE,
    "type  :help nvim<Enter>     if you are new! ",
    "type  :checkhealth<Enter>   to optimize Nvim",
    "type  :q<Enter>             to exit         ",
    "type  :help<Enter>          for help        ",
    INTRO_RULE,
    string.format("type  :help news<Enter>     for v%d.%d notes ", v.major, v.minor),
    INTRO_RULE,
    "Help poor children in Uganda!",
    "type  :help Kuwasha<Enter>  for information ",
  })
end

--- Highlight spans for one intro line, as `{ group, start_byte, end_byte }`.
---
--- Mirrors `do_intro_line()`: the logo's box-drawing characters switch color at
--- the "╲" diagonal, the version line and the rules are highlighted whole, and
--- in the "type ..." lines the `:`, the command name and the `<key>` each get
--- their own color while the prose stays Normal.
---@param line string un-padded
---@param is_logo boolean
---@return table[]
local function intro_spans(line, is_logo)
  local spans = {}

  if is_logo then
    -- Only the multi-byte characters are highlighted; the ASCII spacers keep
    -- the background, which is what makes the strokes read as separate.
    local past_diagonal = false
    local col = 0

    for char in line:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
      if #char > 1 then
        past_diagonal = past_diagonal or char == "╲"
        spans[#spans + 1] = { past_diagonal and INTRO_HL.logo_alt or INTRO_HL.logo, col, col + #char }
      end
      col = col + #char
    end

    return spans
  end

  if vim.startswith(line, "NVIM") then
    return { { INTRO_HL.version, 0, #line } }
  end

  if vim.startswith(line, "─") then
    return { { INTRO_HL.rule, 0, #line } }
  end

  local pos = 1
  while pos <= #line do
    if line:sub(pos, pos) == "<" then
      local close = line:find(">", pos, true) or #line
      spans[#spans + 1] = { INTRO_HL.key, pos - 1, close }
      pos = close + 1
    else
      -- Text run up to the next `<key>`. A colon inside it only counts as a
      -- command prompt when such a key follows, so "https://neovim.io" stays
      -- plain.
      local next_key = line:find("<", pos, true)
      local stop = (next_key or #line + 1) - 1
      local colon = line:find(":", pos, true)

      if next_key and colon and colon <= stop then
        spans[#spans + 1] = { INTRO_HL.key, colon - 1, colon }
        spans[#spans + 1] = { INTRO_HL.command, colon, stop }
      end

      pos = stop + 1
    end
  end

  return spans
end

--- The intro screen as an alpha text element.
---
--- alpha centers a text block by its longest line, which would left-align
--- everything shorter; Neovim centers each line on its own. Padding every line
--- into a field as wide as the widest one reproduces that, at the cost of
--- having to shift the highlight columns by the same amount.
---@return table
local function intro_element()
  local lines = intro_lines()

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  local text, highlights = {}, {}

  for index, line in ipairs(lines) do
    local offset = math.max(math.floor((width - vim.fn.strdisplaywidth(line)) / 2), 0)
    local spans = intro_spans(line, index <= #INTRO_LOGO)

    for _, span in ipairs(spans) do
      span[2] = span[2] + offset
      span[3] = span[3] + offset
    end

    text[index] = string.rep(" ", offset) .. line
    highlights[index] = spans
  end

  -- alpha decides between "one highlight list" and "one per line" by looking at
  -- the first entry, so the first line has to carry at least one span — the
  -- logo always does.
  return { type = "text", val = text, opts = { position = "center", hl = highlights } }
end

-- ---------------------------------------------------------------------------
-- Style "classic": block logo + action buttons
-- ---------------------------------------------------------------------------
--
-- The rows are deliberately ragged, so each one is highlighted across its own
-- length (in bytes — every block is three of them) instead of to a fixed
-- column. That is what the gradient below needs, and it cannot run off the end
-- of a line the way a hard-coded width table can.

local CLASSIC_LOGO = {
      "                                          ",
      "       ███████████           █████      ██",
      "      ███████████             █████ ",
      "      ████████████████ ███████████ ███   ███████",
      "     ████████████████ ████████████ █████ ██████████████",
      "    █████████████████████████████ █████ █████ ████ █████",
      "  ██████████████████████████████████ █████ █████ ████ █████",
      " ██████  ███ █████████████████ ████ █████ █████ ████ ██████",
      " ██████   ██  ███████████████   ██ █████████████████",
    }

return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")
    local ui = require("core.ui")
    local state = require("core.state")
    local utils = require("core.utils")

    local logo_groups = {}
    for index = 1, #CLASSIC_LOGO do
      logo_groups[index] = "AlphaLogo" .. index
    end

    -- One highlight per row, spanning the whole row.
    local function logo_highlights()
      local highlights = {}
      for index, line in ipairs(CLASSIC_LOGO) do
        highlights[index] = { { logo_groups[index], 0, #line } }
      end
      return highlights
    end

    -- The logo fades from the theme's accent toward its secondary glow, so the
    -- dashboard picks up whatever theme is active instead of being a fixed
    -- gradient that clashes with everything but one palette.
    local function apply_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl
      local steps = math.max(#logo_groups - 1, 1)

      for index, group in ipairs(logo_groups) do
        local depth = (index - 1) / steps
        hl(0, group, {
          fg = ui.blend(p.accent, p.glow_secondary or p.accent, 1 - depth),
          bold = p.glow,
        })
      end

      hl(0, "AlphaButtons", { fg = p.fg })
      hl(0, "AlphaShortcut", { fg = p.accent, bold = true })
      hl(0, "AlphaHeader", { fg = p.accent })
      hl(0, "AlphaFooter", { fg = p.muted, italic = true })

      -- The intro style borrows the groups Neovim highlights its own intro
      -- with, which is what keeps it recognizable under every theme. `:colorscheme`
      -- clears links, hence re-linking on each theme change.
      for group, target in pairs({
        [INTRO_HL.logo] = "Special",
        [INTRO_HL.logo_alt] = "String",
        [INTRO_HL.version] = "String",
        [INTRO_HL.rule] = "NonText",
        [INTRO_HL.key] = "SpecialKey",
        [INTRO_HL.command] = "Identifier",
      }) do
        hl(0, group, { link = target })
      end
    end

    --- One dashboard row: shortcut, icon, label, and the command it runs.
    ---@param shortcut string
    ---@param icon string
    ---@param label string
    ---@param command string|function
    local function button(shortcut, icon, label, command)
      local entry = dashboard.button(shortcut, icon .. "  " .. label, command)

      -- alpha's stock <CR> handler replays the command as keystrokes, which
      -- only works for strings and throws on the callbacks below. Running it
      -- directly makes Enter behave like the shortcut key.
      entry.on_press = function()
        if type(command) == "function" then
          command()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(command, true, false, true), "t", false)
        end
      end

      entry.opts.hl = "AlphaButtons"
      entry.opts.hl_shortcut = "AlphaShortcut"
      return entry
    end

    -- Alpha's buttons take a command string or a callback; using callbacks
    -- directly keeps these out of the global namespace, which is where they
    -- previously had to live as `_G._alpha_*` to be reachable from `:lua`.
    local function open_recent_files()
      require("telescope.builtin").oldfiles({ prompt_title = "Recent Files" })
    end

    local function find_files_in_root()
      local workspace = require("core.workspace")
      require("telescope.builtin").find_files({
        cwd = workspace.root(),
        hidden = true,
        no_ignore = true,
        prompt_title = "Find Files \u{2022} " .. workspace.label(),
      })
    end

    local header = {
      type = "text",
      val = CLASSIC_LOGO,
      opts = { position = "center", hl = logo_highlights() },
    }

    local buttons = {
      type = "group",
      val = {
        button("f", "\u{f0e1e}", "Find File", find_files_in_root),
        button("r", "\u{f0954}", "Recent Files", open_recent_files),
        button("g", "\u{f002c}", "Grep", function()
          local workspace = require("core.workspace")
          require("telescope.builtin").live_grep({
            cwd = workspace.root(),
            prompt_title = "Grep \u{2022} " .. workspace.label(),
          })
        end),
        button("e", "\u{f0224}", "New File", "<cmd>ene | startinsert<cr>"),
        { type = "padding", val = 1 },
        button("o", "\u{f0770}", "Open Folder", function() require("core.workspace").open_dialog() end),
        button(
          "d",
          "\u{f0184}",
          utils.desktop_label,
          function() require("core.workspace").open(utils.desktop) end
        ),
        button(
          "x",
          "\u{f04ce}",
          utils.everything_label,
          function() require("core.workspace").open(utils.everything) end
        ),
        button("s", "\u{f09db}", "Restore Session", "<cmd>SessionManager load_session<cr>"),
        { type = "padding", val = 1 },
        button("c", "\u{f0493}", "Configuration", "<cmd>edit $MYVIMRC | cd %:p:h<cr>"),
        button("l", "\u{f0cb2}", "Plugins", "<cmd>Lazy<cr>"),
        button("h", "\u{f02fc}", "Health", "<cmd>checkhealth<cr>"),
        button("q", "\u{f0a48}", "Quit", "<cmd>qa<cr>"),
      },
      opts = { spacing = 1, position = "center" },
    }

    -- Filled in once lazy.nvim knows its own startup time. The intro style
    -- leaves it out: the whole point of that one is to look untouched.
    local footer = { type = "text", val = "", opts = { position = "center", hl = "AlphaFooter" } }

    local layouts = {
      -- A `v_center` group centers the block in the window the way Neovim
      -- centers its intro on the screen.
      intro = function()
        return { { type = "group", val = { intro_element() }, opts = { position = "v_center" } } }
      end,

      classic = function()
        return {
          { type = "padding", val = 3 },
          header,
          { type = "padding", val = 2 },
          buttons,
          footer,
        }
      end,
    }

    --- The style to draw: the persisted choice, or the default when there is
    --- none (or the saved name no longer exists).
    ---@return string
    local function current_style()
      local saved = state.get("dashboard")
      return (type(saved) == "string" and layouts[saved]) and saved or DEFAULT_STYLE
    end

    local function redraw()
      if vim.bo.filetype == "alpha" then
        pcall(alpha.redraw)
      end
    end

    --- Draw `style` from now on.
    ---@param style string
    ---@param opts? { persist?: boolean, notify?: boolean }
    local function set_style(style, opts)
      opts = opts or {}

      if not layouts[style] then
        vim.notify("Unknown dashboard style: " .. style, vim.log.levels.ERROR)
        return
      end

      local config = { layout = layouts[style](), opts = { margin = 5 } }
      alpha.setup(config)

      if opts.persist ~= false then
        state.set("dashboard", style)
      end

      -- Buttons install buffer-local keymaps, so a style switch has to start
      -- from a fresh buffer or the previous style's shortcuts stay live.
      -- `alpha.start()` builds one for any buffer that is not already a
      -- dashboard — hence dropping the filetype first; the old buffer is wiped
      -- by the swap, taking its keymaps with it.
      if vim.bo.filetype == "alpha" then
        vim.bo.filetype = ""
        alpha.start(false, config)
      end

      if opts.notify ~= false then
        vim.notify("Dashboard style: " .. style, vim.log.levels.INFO)
      end
    end

    apply_highlights()
    set_style(current_style(), { persist = false, notify = false })

    ui.on_theme_change(ui.create_augroup("AlphaThemeHighlights"), function()
      apply_highlights()
      redraw()
    end)

    vim.api.nvim_create_user_command("Dashboard", function(cmd)
      local style = cmd.args

      if style == "" then
        -- No argument cycles, which is what <leader>ua rides on.
        local current, index = current_style(), 1
        for i, name in ipairs(STYLES) do
          if name == current then
            index = i % #STYLES + 1
          end
        end
        style = STYLES[index]
      end

      set_style(style)
    end, {
      nargs = "?",
      complete = function() return STYLES end,
      desc = "Switch dashboard style (no argument cycles)",
    })

    --- Plugin load stats, once lazy.nvim has finished starting up.
    ---@return boolean ready
    local function set_footer()
      local ok, lazy = pcall(require, "lazy")
      if not ok then
        return false
      end

      local stats = lazy.stats()
      if stats.startuptime == 0 then
        return false -- not measured yet
      end

      footer.val =
        string.format("\u{f0e7}  %d plugins loaded in %.0f ms", stats.loaded, stats.startuptime)
      redraw()

      return true
    end

    -- The event may already have fired by the time alpha configures itself.
    if not set_footer() then
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        once = true,
        callback = set_footer,
      })
    end
  end,
}
