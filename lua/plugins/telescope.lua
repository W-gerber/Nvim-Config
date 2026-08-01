-- Pickers.
--
-- One layout and one border treatment for everything, so find-files, grep and
-- the rest read as the same tool: the prompt and the result list are drawn as a
-- single panel (the prompt's bottom edge is left open and the results' top
-- corners are T-junctions), with the preview as its own box beside them.
--
-- Every window stays transparent — see the note on `ui.pane_bg()`. Structure
-- comes from the rims, the title chips and the selection bar, never from a
-- background.
--
-- Searching is scoped by two session-wide toggles rather than by two separate
-- "and also the hidden ones" keybindings: `<A-h>` for dotfiles and `<A-i>` for
-- everything .gitignore hides. Both re-run the picker in place, keeping what
-- you had typed, and the prompt title says which mode you are in.

local icons = require("core.icons")

-- Order is { top, right, bottom, left, top-left, top-right, bottom-right,
-- bottom-left }.
local BORDERS = {
  prompt = { "\u{2500}", "\u{2502}", " ", "\u{2502}", "\u{256d}", "\u{256e}", "\u{2502}", "\u{2502}" },
  results = { "\u{2500}", "\u{2502}", "\u{2500}", "\u{2502}", "\u{251c}", "\u{2524}", "\u{256f}", "\u{2570}" },
  preview = { "\u{2500}", "\u{2502}", "\u{2500}", "\u{2502}", "\u{256d}", "\u{256e}", "\u{256f}", "\u{2570}" },
}

-- Paths never worth walking into, whatever the repo says. `.git` is excluded by
-- ripgrep's glob too — this catches the pickers that don't shell out to rg.
--
-- Kept short on purpose: everything else is `.gitignore`'s job, which is what
-- makes "include ignored files" a meaningful toggle rather than one that still
-- hides half of what it claims to show.
local ALWAYS_IGNORE = {
  "%.git[/\\]",
  "%.hg[/\\]",
  "%.svn[/\\]",
  "node_modules[/\\]",
  "%.venv[/\\]",
  "__pycache__[/\\]",
  "%.lock$",
  "%.png$",
  "%.jpg$",
  "%.jpeg$",
  "%.gif$",
  "%.webp$",
  "%.ico$",
  "%.pdf$",
  "%.zip$",
  "%.7z$",
  "%.exe$",
  "%.dll$",
  "%.class$",
  "%.o$",
}

-- Session-wide search scope, flipped by the toggles below.
--
--   hidden  — dotfiles and dot-directories are searched
--   ignored — .gitignore/.ignore are ignored, i.e. *everything* is searched
--
-- Hidden defaults on because a config directory is mostly dotfiles; ignored
-- defaults off because `node_modules` in the result list is what makes a picker
-- feel slow.
local scope = { hidden = true, ignored = false }

--- A short " (+hidden +ignored)" tag for the prompt title, so the current scope
--- is visible instead of remembered.
---@return string
local function scope_tag()
  local flags = {}
  if scope.hidden then
    flags[#flags + 1] = "\u{f0453}" -- eye
  end
  if scope.ignored then
    flags[#flags + 1] = "\u{f0450}" -- plus-circle
  end

  return #flags > 0 and ("  " .. table.concat(flags, " ")) or ""
end

--- Ripgrep arguments for grep pickers.
---
--- `--hidden` alone is not enough to search a hidden *folder*: ripgrep still
--- skips `.github/` unless the directory itself is allowed through, which is
--- what makes the explicit `!**/.git/*` exclusion necessary rather than relying
--- on rg's defaults.
---@return string[]
local function rg_args()
  local args = {
    "--glob=!**/.git/*",
    "--glob=!**/node_modules/*",
    "--glob=!**/.venv/*",
    -- Without this a single minified file or a stray binary can hang the picker
    -- on one enormous line.
    "--max-columns=500",
    "--max-columns-preview",
  }

  if scope.hidden then
    table.insert(args, 1, "--hidden")
  end

  if scope.ignored then
    -- Searches files .gitignore excludes; the globs above still hold, so this
    -- never means "walk into .git".
    table.insert(args, 1, "--no-ignore")
  end

  return args
end

--- The shared picker layout. `overrides` adjusts one picker's proportions.
---@param overrides? table
---@return table
local function layout(overrides)
  return vim.tbl_deep_extend("force", {
    prompt_position = "top",
    width = 0.9,
    height = 0.85,
    -- Below `flip_columns` the preview moves under the list instead of being
    -- squeezed into a column too narrow to read.
    flex = { flip_columns = 140 },
    horizontal = { preview_width = 0.55, preview_cutoff = 100 },
    vertical = { preview_height = 0.5 },
  }, overrides or {})
end

--- `name  󰉋 parent/dir`, so the filename is what your eye lands on.
local function finder_path(_, path)
  local name = vim.fn.fnamemodify(path, ":t")
  local parent = vim.fn.fnamemodify(path, ":h")

  if parent == "." or parent == "" then
    return name
  end

  parent = vim.fn.fnamemodify(parent, ":~:.")
  return string.format("%s  \u{f024b} %s", name, parent)
end

-- ---------------------------------------------------------------------------
-- Pickers
-- ---------------------------------------------------------------------------

local open_find_files, open_live_grep

---@param extra? table
function open_find_files(extra)
  local builtin = require("telescope.builtin")
  local workspace = require("core.workspace")

  builtin.find_files(vim.tbl_extend("force", {
    cwd = workspace.root(),
    hidden = scope.hidden,
    no_ignore = scope.ignored,
    -- Without this, a parent directory's .gitignore still filters results even
    -- when "include ignored" is on.
    no_ignore_parent = scope.ignored,
    -- The always-ignore list is dropped entirely in ignored mode, so the toggle
    -- means what it says.
    file_ignore_patterns = scope.ignored and {} or ALWAYS_IGNORE,
    follow = true,
    prompt_title = "Files \u{2022} " .. workspace.label() .. scope_tag(),
    results_title = "Root Files",
    preview_title = "Preview",
    layout_strategy = "horizontal",
    sorting_strategy = "ascending",
    path_display = finder_path,
    layout_config = layout({ horizontal = { preview_width = 0.52 } }),
  }, extra or {}))
end

---@param extra? table
function open_live_grep(extra)
  local builtin = require("telescope.builtin")
  local workspace = require("core.workspace")

  builtin.live_grep(vim.tbl_extend("force", {
    cwd = workspace.root(),
    prompt_title = "Grep \u{2022} " .. workspace.label() .. scope_tag(),
    results_title = "Matches",
    preview_title = "Context",
    layout_strategy = "horizontal",
    sorting_strategy = "ascending",
    path_display = finder_path,
    file_ignore_patterns = scope.ignored and {} or ALWAYS_IGNORE,
    -- Grep results are one line of context each; the preview is where the
    -- match actually makes sense, so it gets the larger half.
    layout_config = layout({ width = 0.95, height = 0.88, horizontal = { preview_width = 0.6 } }),
    additional_args = rg_args,
  }, extra or {}))
end

---@param extra? table
local function open_file_browser(extra)
  local telescope = require("telescope")
  local workspace = require("core.workspace")

  telescope.extensions.file_browser.file_browser(vim.tbl_extend("force", {
    cwd = workspace.root(),
    prompt_title = "Browse \u{2022} " .. workspace.label(),
    results_title = "Directory",
    preview_title = "Preview",
    layout_config = layout({ horizontal = { preview_width = 0.5 } }),
  }, extra or {}))
end

-- ---------------------------------------------------------------------------
-- Scope toggles
-- ---------------------------------------------------------------------------

--- Close the picker and reopen it with the current `scope`, carrying the typed
--- prompt and the directory across.
---
--- Reopening rather than refreshing the finder in place is deliberate: `hidden`
--- and `no_ignore` are baked into the command the finder was constructed with,
--- so the only way to change them is to build a new one.
---@param open fun(extra: table)
---@return fun(prompt_bufnr: integer)
local function reopen_with(open)
  return function(prompt_bufnr)
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local picker = action_state.get_current_picker(prompt_bufnr)
    local prompt = picker and picker:_get_prompt() or ""
    local cwd = picker and picker.cwd or nil

    actions.close(prompt_bufnr)

    -- Scheduled so the closing picker has finished tearing down its windows
    -- before the replacement asks for its own.
    vim.schedule(function() open({ default_text = prompt, cwd = cwd }) end)
  end
end

---@param key "hidden"|"ignored"
---@param open fun(extra: table)
---@return fun(prompt_bufnr: integer)
local function toggle_scope(key, open)
  return function(prompt_bufnr)
    scope[key] = not scope[key]
    reopen_with(open)(prompt_bufnr)
  end
end

--- The two toggles, for a picker opened by `open`.
---@param open fun(extra: table)
---@return table
local function scope_mappings(open)
  local maps = {
    ["<A-h>"] = toggle_scope("hidden", open),
    ["<A-i>"] = toggle_scope("ignored", open),
  }

  return { i = maps, n = vim.deepcopy(maps) }
end

-- ---------------------------------------------------------------------------

return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
  },
  cmd = { "Telescope" },
  keys = {
    { "<leader>ff", function() open_find_files() end, desc = "Find files (workspace)" },
    { "<leader>fg", function() open_live_grep() end, desc = "Grep (workspace)" },
    { "<leader>fe", function() open_file_browser() end, desc = "File browser (workspace)" },
    {
      "<leader>fE",
      function()
        -- Browse the directory of the file you are in, with that file already
        -- selected — the "where am I?" question the tree answers slowly.
        open_file_browser({
          cwd = vim.fn.expand("%:p:h"),
          select_buffer = true,
          prompt_title = "Browse \u{2022} " .. vim.fn.expand("%:p:h:t"),
        })
      end,
      desc = "File browser (current file)",
    },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Open buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
    { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
    { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
    { "<leader>f/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search in buffer" },
    { "<leader>fR", "<cmd>Telescope resume<cr>", desc = "Resume last picker" },
  },
  config = function()
    local ui = require("core.ui")
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local sorters = require("telescope.sorters")

    -- Required by module path rather than through `telescope.extensions`, which
    -- is only populated once the extension has been loaded — and loading it has
    -- to happen after `setup()`, which is where these mappings are needed.
    local ok_fb, fb_actions = pcall(require, "telescope._extensions.file_browser.actions")
    if not ok_fb then
      fb_actions = nil
    end

    telescope.setup({
      defaults = {
        -- No static cwd: pickers follow Neovim's cwd, i.e. the open workspace.
        path_display = finder_path,
        layout_strategy = "horizontal",
        layout_config = layout(),
        sorting_strategy = "ascending",
        dynamic_preview_title = true,
        prompt_prefix = icons.ui.search .. "  ",
        selection_caret = icons.ui.caret .. " ",
        entry_prefix = "  ",
        multi_icon = icons.file.modified .. " ",

        -- fzy scores a run of adjacent characters far above the same letters
        -- scattered across a path, which is what you actually mean when you
        -- type `telescope` and want `plugins/telescope.lua` above
        -- `themes/tokyonight.lua`. Telescope's default sorter treats both as
        -- equally good matches.
        file_sorter = sorters.get_fzy_sorter,
        generic_sorter = sorters.get_fzy_sorter,

        -- Blending would composite the picker against the buffer underneath,
        -- which is what stops a transparent terminal showing through.
        winblend = 0,
        borderchars = BORDERS,
        color_devicons = true,
        file_ignore_patterns = ALWAYS_IGNORE,

        -- `vimgrep_arguments` is deliberately left at telescope's default. The
        -- scope-dependent flags belong in `additional_args`, which is evaluated
        -- per invocation — baking them in here would freeze whatever `scope`
        -- happened to be at startup.

        mappings = {
          i = {
            -- How a result opens. Spelled out rather than left to the defaults
            -- so the set is visible and `<C-s>` means "horizontal split" here
            -- the way it does everywhere else in this config.
            ["<CR>"] = actions.select_default,
            ["<C-v>"] = actions.select_vertical,
            ["<C-s>"] = actions.select_horizontal,
            ["<C-t>"] = actions.select_tab,

            -- Movement.
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<C-u>"] = actions.preview_scrolling_up,

            -- Multi-select, then send the lot somewhere useful.
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.smart_add_to_qflist,

            ["<C-c>"] = actions.close,
            ["<Esc>"] = actions.close,
          },
          n = {
            ["q"] = actions.close,
            ["<Esc>"] = actions.close,

            ["<CR>"] = actions.select_default,
            ["<C-v>"] = actions.select_vertical,
            ["<C-s>"] = actions.select_horizontal,
            ["<C-t>"] = actions.select_tab,

            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["gg"] = actions.move_to_top,
            ["G"] = actions.move_to_bottom,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<C-u>"] = actions.preview_scrolling_up,

            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
          },
        },
      },

      pickers = {
        find_files = {
          hidden = true,
          prompt_title = "Files",
          results_title = "Results",
          preview_title = "Preview",
          layout_config = layout({ horizontal = { preview_width = 0.52 } }),
          mappings = scope_mappings(open_find_files),
        },

        live_grep = {
          -- Fuzzy-match the matched *text*, not the path it came from —
          -- otherwise every result in a deeply nested file scores well for
          -- reasons that have nothing to do with the code.
          only_sort_text = true,
          prompt_title = "Grep",
          results_title = "Matches",
          preview_title = "Context",
          additional_args = rg_args,
          layout_config = layout({ width = 0.95, height = 0.88, horizontal = { preview_width = 0.6 } }),
          mappings = scope_mappings(open_live_grep),
        },

        grep_string = {
          prompt_title = "Grep Word",
          results_title = "Matches",
          preview_title = "Context",
          additional_args = rg_args,
          layout_config = layout({ width = 0.95, height = 0.88, horizontal = { preview_width = 0.6 } }),
        },

        buffers = {
          show_all_buffers = true,
          sort_mru = true,
          sort_lastused = true,
          ignore_current_buffer = true,
          previewer = false,
          prompt_title = "Buffers",
          -- No preview, so the panel shrinks to the size of a list.
          layout_config = layout({ width = 0.6, height = 0.6 }),
          mappings = {
            i = { ["<C-x>"] = actions.delete_buffer },
            n = { ["dd"] = actions.delete_buffer, ["<C-x>"] = actions.delete_buffer },
          },
        },

        current_buffer_fuzzy_find = {
          prompt_title = "Search Buffer",
          results_title = "Lines",
          layout_config = layout({ horizontal = { preview_width = 0.5 } }),
        },

        keymaps = { prompt_title = "Keymaps", layout_config = layout({ width = 0.8 }) },
        commands = { prompt_title = "Commands", layout_config = layout({ width = 0.8 }) },
        help_tags = { prompt_title = "Help" },
        oldfiles = { prompt_title = "Recent Files", cwd_only = false },
        diagnostics = { prompt_title = "Diagnostics" },
      },

      extensions = {
        file_browser = {
          -- Netrw is already off (see the rtp list in init.lua) and Neo-tree
          -- claims directory buffers via `hijack_netrw_behavior`. Two plugins
          -- fighting over `:e some/dir` is one too many.
          hijack_netrw = false,

          -- Dotfiles visible in both views, matching what the other pickers
          -- search. `<A-h>` still hides them for a noisy directory.
          hidden = { file_browser = true, folder_browser = true },

          -- Directories first, then files — the ordering every file manager
          -- uses, and the reason you can find a folder without reading names.
          grouped = true,

          -- Browsing is not searching: when you open the browser on a project
          -- you generally do want to see `dist/` and `.env`.
          respect_gitignore = false,

          git_status = true,
          follow_symlinks = false,

          -- Size and date, no mode column: permissions are noise on Windows and
          -- the width is better spent on the name.
          display_stat = { date = true, size = true, mode = false },

          -- Show the directory being browsed in the prompt, so the title is not
          -- the only clue about where you are.
          prompt_path = true,

          -- Typing a name that doesn't exist and pressing <S-CR> creates it.
          create_from_prompt = true,

          dir_icon = icons.file.folder,
          dir_icon_hl = "NeoTreeDirectoryIcon",

          -- `vim.ui.input`, which noice renders as a styled float rather than a
          -- bare cmdline prompt.
          use_ui_input = true,

          layout_config = layout({ horizontal = { preview_width = 0.5 } }),

          mappings = fb_actions and {
            i = {
              -- File operations. Alt-modified so every one of them is reachable
              -- without leaving the prompt.
              ["<A-c>"] = fb_actions.create,
              ["<S-CR>"] = fb_actions.create_from_prompt,
              ["<A-r>"] = fb_actions.rename,
              ["<A-m>"] = fb_actions.move,
              ["<A-y>"] = fb_actions.copy,
              ["<A-d>"] = fb_actions.remove,
              ["<A-o>"] = fb_actions.open, -- open in the system handler

              -- Navigation.
              ["<C-g>"] = fb_actions.goto_parent_dir,
              ["<C-e>"] = fb_actions.goto_home_dir,
              ["<C-w>"] = fb_actions.goto_cwd,
              ["<C-t>"] = fb_actions.change_cwd,
              ["<C-f>"] = fb_actions.toggle_browser, -- files <-> folders
              ["<bs>"] = fb_actions.backspace,

              -- Same two scope toggles as the other pickers, same keys.
              ["<A-h>"] = fb_actions.toggle_hidden,
              ["<A-i>"] = fb_actions.toggle_respect_gitignore,

              -- Sorting.
              ["<A-s>"] = fb_actions.sort_by_size,
              ["<A-t>"] = fb_actions.sort_by_date,

              ["<C-a>"] = fb_actions.toggle_all,
            },
            n = {
              -- Single letters in normal mode, matching Neo-tree's where they
              -- can: `a`dd, `r`ename, `d`elete, `c`opy, `m`ove.
              ["a"] = fb_actions.create,
              ["r"] = fb_actions.rename,
              ["m"] = fb_actions.move,
              ["c"] = fb_actions.copy,
              ["d"] = fb_actions.remove,
              ["o"] = fb_actions.open,

              ["u"] = fb_actions.goto_parent_dir,
              ["~"] = fb_actions.goto_home_dir,
              ["w"] = fb_actions.goto_cwd,
              ["t"] = fb_actions.change_cwd,
              ["f"] = fb_actions.toggle_browser,

              ["H"] = fb_actions.toggle_hidden,
              ["I"] = fb_actions.toggle_respect_gitignore,

              ["s"] = fb_actions.sort_by_size,
              ["S"] = fb_actions.sort_by_date,

              ["<C-a>"] = fb_actions.toggle_all,
            },
          } or nil,
        },
      },
    })

    pcall(telescope.load_extension, "file_browser")

    -- Theme-aware highlights, re-applied whenever the theme changes.
    --
    -- The pickers stay see-through on purpose: every window is `NONE`, so what
    -- is behind them shows through instead of a panel. Only the two bars that
    -- have to be visible carry a background, and they use `ui.frost()` rather
    -- than the accent-tinted surfaces — on a theme with a vivid accent those
    -- turn the selected row and the previewed line into colored film.
    local function apply_telescope_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl
      local transparent = "NONE"
      local selection_bg = ui.frost(0.16)

      -- Rims: the prompt is where you are, so it gets the lit edge and the
      -- others recede — the same top-lit/bottom-dim idea as the glass panels.
      local rim = ui.blend(p.accent, p.bg, 0.45)
      local rim_active = ui.blend(p.accent, p.fg, 0.65)

      hl(0, "TelescopeNormal", { bg = transparent, fg = p.fg })
      hl(0, "TelescopeBorder", { bg = transparent, fg = rim })
      hl(0, "TelescopePromptNormal", { bg = transparent, fg = p.fg })
      hl(0, "TelescopePromptBorder", { bg = transparent, fg = rim_active })
      hl(0, "TelescopeResultsNormal", { bg = transparent, fg = p.fg })
      hl(0, "TelescopeResultsBorder", { bg = transparent, fg = rim })
      hl(0, "TelescopePreviewNormal", { bg = transparent, fg = p.fg })
      hl(0, "TelescopePreviewBorder", { bg = transparent, fg = rim })

      -- Titles: one solid chip on the prompt, plain accent text elsewhere, so
      -- there is exactly one thing shouting per picker.
      hl(0, "TelescopePromptTitle", { bg = p.accent, fg = ui.contrast(p.accent), bold = true })
      hl(0, "TelescopeResultsTitle", { bg = transparent, fg = p.accent, bold = true })
      hl(0, "TelescopePreviewTitle", { bg = transparent, fg = p.accent, bold = true })
      hl(0, "TelescopeTitle", { bg = transparent, fg = p.accent, bold = true })

      hl(0, "TelescopePromptPrefix", { bg = transparent, fg = p.accent, bold = true })
      hl(0, "TelescopePromptCounter", { bg = transparent, fg = p.muted })

      hl(0, "TelescopeSelection", { bg = selection_bg, fg = p.fg, bold = true })
      hl(0, "TelescopeSelectionCaret", { bg = selection_bg, fg = p.accent, bold = true })
      hl(0, "TelescopeMultiSelection", { fg = p.purple, bold = true })
      hl(0, "TelescopeMultiIcon", { fg = p.purple })
      hl(0, "TelescopeMatching", { fg = p.accent, bold = true })

      hl(0, "TelescopeResultsComment", { fg = p.muted })
      hl(0, "TelescopeResultsDiffAdd", { fg = p.green })
      hl(0, "TelescopeResultsDiffChange", { fg = p.yellow })
      hl(0, "TelescopeResultsDiffDelete", { fg = p.red })
      hl(0, "TelescopePreviewLine", { bg = ui.frost(0.1) })
      hl(0, "TelescopePreviewMatch", { fg = p.accent, bold = true })

      -- File browser: the same three columns the explorer uses — one icon, the
      -- name, then git state — so the browser and Neo-tree agree on what a
      -- modified file looks like.
      hl(0, "TelescopePreviewDirectory", { fg = p.accent, bold = true })
      hl(0, "TelescopeResultsFileIcon", { fg = p.purple })
      hl(0, "TelescopeBufferLoaded", { fg = p.green })
    end

    apply_telescope_highlights()

    local tele_group = ui.create_augroup("TelescopeHighlights")
    ui.on_theme_change(tele_group, apply_telescope_highlights)
  end,
}
