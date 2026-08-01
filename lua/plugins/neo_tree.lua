-- File explorer.
--
-- Laid out as three columns that always line up: indent guides, then one icon,
-- then the name, with git state and diagnostics riding on the right. Everything
-- is see-through — the tree has no pane of its own, so a transparent terminal
-- shows through it the same way it does through the editor.

local icons = require("core.icons")

-- Tabs across the top of the tree. Padded so the active one reads as a chip
-- rather than a word with a line under it.
local SOURCES = {
  { source = "filesystem", display_name = " \u{f0770} Files " }, -- nf-md-folder
  { source = "buffers", display_name = " \u{f0219} Buffers " }, -- nf-md-file_multiple
  { source = "git_status", display_name = " \u{f02a2} Git " }, -- nf-md-source_branch
}

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = require("core.workspace").root() })
      end,
      desc = "Toggle Neo-tree",
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    local ui = require("core.ui")

    require("neo-tree").setup({
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      -- `Makefile` next to `main.c`, not in a separate uppercase block above it.
      sort_case_insensitive = true,
      -- The tree is chrome, not content: no line numbers, no sign column, no
      -- fold gutter competing with the indent guides.
      --
      -- File operations are spelled out rather than left to Neo-tree's defaults
      -- (which these merge into). They are the reason to keep a tree at all
      -- next to a fuzzy finder, and an unwritten mapping is one nobody uses.
      window = {
        width = 34,
        mappings = {
          -- Opening
          ["<space>"] = "toggle_node",
          ["<cr>"] = "open",
          ["S"] = "open_split",
          ["s"] = "open_vsplit",
          ["t"] = "open_tabnew",
          ["w"] = "open_with_window_picker",
          ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = false } },
          ["l"] = "open",
          ["h"] = "close_node",
          ["z"] = "close_all_nodes",
          ["Z"] = "expand_all_nodes",

          -- Creating. `a` prompts for a name; ending it with `/` makes a
          -- directory, which is why there is no separate "new folder".
          ["a"] = { "add", config = { show_path = "relative" } },
          ["A"] = "add_directory",

          -- Moving and copying. `c`/`m` prompt for the destination path;
          -- `y`/`x`/`p` are the clipboard equivalents for moving a batch.
          ["r"] = "rename",
          ["c"] = { "copy", config = { show_path = "relative" } },
          ["m"] = { "move", config = { show_path = "relative" } },
          ["y"] = "copy_to_clipboard",
          ["x"] = "cut_to_clipboard",
          ["p"] = "paste_from_clipboard",
          ["d"] = "delete",

          -- `Y` copies the path itself, for pasting into a terminal or a chat.
          ["Y"] = function(state)
            local node = state.tree:get_node()
            if node then
              vim.fn.setreg("+", node.path)
              vim.notify(node.path, vim.log.levels.INFO)
            end
          end,

          ["R"] = "refresh",
          ["q"] = "close_window",
          ["?"] = "show_help",
        },
      },
      source_selector = {
        winbar = true,
        statusline = false,
        sources = SOURCES,
        content_layout = "center",
        tabs_layout = "equal",
        show_separator_on_edge = false,
        separator = { left = "", right = "" },
        highlight_tab = "NeoTreeTabInactive",
        highlight_tab_active = "NeoTreeTabActive",
        highlight_background = "NeoTreeTabInactive",
        highlight_separator = "NeoTreeTabSeparatorInactive",
        highlight_separator_active = "NeoTreeTabSeparatorActive",
      },
      filesystem = {
        follow_current_file = { enabled = true, leave_dirs_open = true },
        group_empty_dirs = true,
        hijack_netrw_behavior = "open_default",
        -- Keep the tree rooted at the workspace: follow :cd (workspace.open).
        bind_to_cwd = true,
        use_libuv_file_watcher = true, -- refresh on changes made outside Neovim
        -- Filtering lives on the filesystem source rather than in the global
        -- `window.mappings` above: `toggle_hidden` and the filter commands
        -- don't exist on the buffers or git_status sources, and a mapping to a
        -- command a source has never heard of is an error message on keypress.
        window = {
          mappings = {
            ["H"] = "toggle_hidden",
            ["/"] = "fuzzy_finder",
            ["D"] = "fuzzy_finder_directory",
            ["f"] = "filter_on_submit",
            ["<C-x>"] = "clear_filter",
            ["[g"] = "prev_git_modified",
            ["]g"] = "next_git_modified",
          },
        },
        filtered_items = {
          -- Dotfiles are shown, matching what the pickers search. Only the
          -- directories nobody wants to expand are hidden, and `H` still
          -- toggles even those.
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false,
          hide_by_name = { "node_modules", ".git", "__pycache__", ".DS_Store", "thumbs.db" },
          never_show = {},
        },
      },
      default_component_configs = {
        container = { enable_character_fade = true },
        indent = {
          with_markers = true,
          indent_size = 2,
          padding = 1,
          indent_marker = "\u{2502}", -- │
          last_indent_marker = "\u{2570}", -- ╰, matching every other rim in the UI
          with_expanders = true,
          expander_collapsed = icons.ui.chevron_right,
          expander_expanded = icons.ui.chevron_down,
          expander_highlight = "NeoTreeExpander",
        },
        icon = {
          folder_closed = icons.file.folder,
          folder_open = icons.file.folder_open,
          folder_empty = icons.file.folder_empty,
          folder_empty_open = icons.file.folder_empty,
          default = "\u{f0219}", -- only for types devicons has no glyph for
        },
        modified = { symbol = icons.file.modified },
        name = { trailing_slash = false, use_git_status_colors = true },
        git_status = {
          -- Symbols rather than letters: they sit in one column and read as
          -- state, not as text competing with the filename.
          symbols = {
            added = icons.git.added,
            modified = icons.git.modified,
            deleted = icons.git.removed,
            renamed = icons.git.renamed,
            untracked = icons.git.untracked,
            ignored = icons.git.ignored,
            staged = "\u{f00c}", -- check
            conflict = "\u{f071}", -- warning triangle
          },
        },
        diagnostics = {
          symbols = {
            error = icons.diagnostics.error,
            warn = icons.diagnostics.warn,
            info = icons.diagnostics.info,
            hint = icons.diagnostics.hint,
          },
          highlights = {
            error = "DiagnosticError",
            warn = "DiagnosticWarn",
            info = "DiagnosticInfo",
            hint = "DiagnosticHint",
          },
        },
      },
    })

    -- Explorer colors follow the active theme. This used to hard-code the neon
    -- palette plus a hand-rolled "is this theme light?" brightness check, which
    -- meant every non-neon theme got neon icons and near-invisible text.
    local function apply_neotree_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl

      -- Every surface stays transparent; the tree is separated from the editor
      -- by its own separator line, not by a background.
      hl(0, "NeoTreeNormal", { fg = p.fg, bg = "NONE" })
      hl(0, "NeoTreeNormalNC", { fg = p.fg, bg = "NONE" })
      hl(0, "NeoTreeEndOfBuffer", { fg = p.bg, bg = "NONE" })
      hl(0, "NeoTreeWinSeparator", { fg = ui.blend(p.accent, p.bg, 0.35), bg = "NONE" })
      hl(0, "NeoTreeCursorLine", { bg = ui.frost(0.12) })

      -- Header: the workspace name, in the same accent the dashboard and the
      -- statusline use for "where am I".
      hl(0, "NeoTreeRootName", { fg = p.accent, bg = "NONE", bold = true })
      hl(0, "NeoTreeTitleBar", { fg = p.accent, bg = ui.pane_bg(0.14), bold = true })

      -- Source tabs. The active one is an accent chip; the others recede.
      hl(0, "NeoTreeTabActive", { fg = p.accent, bg = ui.frost(0.14), bold = true })
      hl(0, "NeoTreeTabInactive", { fg = p.muted, bg = "NONE" })
      hl(0, "NeoTreeTabSeparatorActive", { fg = ui.frost(0.14), bg = ui.frost(0.14) })
      hl(0, "NeoTreeTabSeparatorInactive", { fg = p.bg, bg = "NONE" })

      -- Tree body.
      hl(0, "NeoTreeDirectoryIcon", { fg = p.accent, bg = "NONE" })
      hl(0, "NeoTreeDirectoryName", { fg = p.fg, bg = "NONE", bold = true })
      hl(0, "NeoTreeFileIcon", { fg = p.purple, bg = "NONE" })
      hl(0, "NeoTreeFileName", { fg = p.fg, bg = "NONE" })
      hl(0, "NeoTreeFileNameOpened", { fg = p.accent, bg = "NONE", bold = true })
      hl(0, "NeoTreeIndentMarker", { fg = ui.blend(p.muted, p.bg, 0.45), bg = "NONE" })
      hl(0, "NeoTreeExpander", { fg = p.accent, bg = "NONE" })
      hl(0, "NeoTreeDotfile", { fg = p.muted, bg = "NONE" })
      hl(0, "NeoTreeHiddenByName", { fg = p.muted, bg = "NONE" })
      hl(0, "NeoTreeSymbolicLinkTarget", { fg = p.cyan, italic = true })
      hl(0, "NeoTreeDimText", { fg = ui.blend(p.muted, p.bg, 0.55) })
      hl(0, "NeoTreeMessage", { fg = p.muted, italic = true })
      hl(0, "NeoTreeFilterTerm", { fg = p.accent, bold = true })

      -- Git and diagnostics columns.
      hl(0, "NeoTreeModified", { fg = p.orange, bg = "NONE" })
      hl(0, "NeoTreeGitAdded", { fg = p.green })
      hl(0, "NeoTreeGitModified", { fg = p.yellow })
      hl(0, "NeoTreeGitDeleted", { fg = p.red })
      hl(0, "NeoTreeGitRenamed", { fg = p.purple })
      hl(0, "NeoTreeGitStaged", { fg = p.green })
      hl(0, "NeoTreeGitUnstaged", { fg = p.orange })
      hl(0, "NeoTreeGitUntracked", { fg = p.purple })
      hl(0, "NeoTreeGitConflict", { fg = p.red, bold = true })
      hl(0, "NeoTreeGitIgnored", { fg = ui.blend(p.muted, p.bg, 0.5) })

      -- Popups (rename, filter, ...) borrow the glass rim.
      hl(0, "NeoTreeFloatNormal", { fg = p.fg, bg = ui.pane_bg(0.1) })
      hl(0, "NeoTreeFloatBorder", { fg = ui.blend(p.accent, p.bg, 0.5), bg = ui.pane_bg(0.1) })
      hl(0, "NeoTreeFloatTitle", { fg = ui.contrast(p.accent), bg = p.accent, bold = true })
    end

    apply_neotree_highlights()
    ui.on_theme_change(ui.create_augroup("NeoTreeHighlights"), apply_neotree_highlights)
  end,
}
