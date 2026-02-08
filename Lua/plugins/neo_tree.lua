return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    local neotree = require("neo-tree")
    local utils = require("core.utils")
    neotree.setup({
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      window = {
        width = 30,
        mappings = {
          ["<space>"] = "toggle_node",
          ["<cr>"] = "open",
          ["S"] = "open_split",
          ["s"] = "open_vsplit",
          ["t"] = "open_tabnew",
          ["q"] = "close_window",
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        group_empty_dirs = true,
        hijack_netrw_behavior = "open_default",
        cwd = utils.everything,
      },
      default_component_configs = {
        indent = {
          with_markers = true,
          indent_size = 2,
          padding = 1,
          indent_marker = "│",
          last_indent_marker = "└",
          expander_collapsed = "",
          expander_expanded = "",
        },
        icon = { folder_closed = "", folder_open = "", folder_empty = "" },
        modified = { symbol = "●" },
        name = {
          trailing_slash = false,
          use_git_status_colors = true,
        },
        git_status = {
          symbols = {
            added = "",
            modified = "",
            deleted = "",
            renamed = "",
            untracked = "",
            ignored = "",
          },
        },
      },
    })

    vim.keymap.set("n", "<leader>e", function()
      require("neo-tree.command").execute({ toggle = true, dir = utils.everything })
    end, { desc = "Toggle Neo-tree in Everything folder", silent = true, noremap = true })

    -- Function to apply neo-tree highlights based on current theme
    local function apply_neotree_highlights()
      local ok_theme, theme = pcall(require, "theme")
      local c = (ok_theme and theme and theme.neon) or {
        cyan = "#00d7ff",
        hotpink = "#ff2d95",
        lime = "#b7ff3a",
        purple = "#9d7cff",
        orange = "#ff9e1b",
        white = "#ffffff",
        gray = "#808080",
        bg = "#080808",
      }

      local function is_light_theme()
        -- Prefer actual rendered background over variables that might not update.
        local ok_normal, normal = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
        if ok_normal and type(normal) == "table" and type(normal.bg) == "number" then
          local bg = normal.bg
          local r = math.floor(bg / 0x10000) % 0x100
          local g = math.floor(bg / 0x100) % 0x100
          local b = bg % 0x100
          -- Simple perceived brightness; threshold tuned for typical themes.
          local brightness = (r * 299 + g * 587 + b * 114) / 1000
          return brightness >= 140
        end

        if vim.o.background == "light" then
          return true
        end

        local colors_name = tostring(vim.g.colors_name or ""):lower()
        if colors_name ~= "" then
          return colors_name:find("light", 1, true) ~= nil
        end

        local current_theme = tostring(vim.g.current_theme or ""):lower()
        return current_theme:find("light", 1, true) ~= nil
      end

      local light = is_light_theme()
      local text_color = light and "#000000" or c.white

      local function hl(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
      end

      hl("NeoTreeNormal", { fg = text_color, bg = "NONE" })
      hl("NeoTreeNormalNC", { fg = text_color, bg = "NONE" })
      hl("NeoTreeWinSeparator", { fg = c.gray, bg = "NONE" })
      hl("NeoTreeCursorLine", { bg = "NONE", underline = true, sp = c.cyan })
      hl("NeoTreeRootName", { fg = light and "#000000" or c.hotpink, bg = "NONE", bold = true })
      hl("NeoTreeDirectoryIcon", { fg = c.cyan, bg = "NONE" })
      hl("NeoTreeDirectoryName", { fg = text_color, bg = "NONE", bold = true })
      hl("NeoTreeFileIcon", { fg = c.purple, bg = "NONE" })
      hl("NeoTreeFileName", { fg = text_color, bg = "NONE" })
      hl("NeoTreeFileNameOpened", { fg = light and "#000000" or c.lime, bg = "NONE", bold = true })
      hl("NeoTreeModified", { fg = c.orange, bg = "NONE" })
      hl("NeoTreeGitAdded", { fg = c.lime })
      hl("NeoTreeGitModified", { fg = c.hotpink })
      hl("NeoTreeGitDeleted", { fg = c.hotpink })
      hl("NeoTreeIndentMarker", { fg = c.gray, bg = "NONE" })
      hl("NeoTreeFloatBorder", { fg = c.purple, bg = "NONE" })
      hl("NeoTreeFloatTitle", { fg = text_color, bg = "NONE", bold = true })
    end

    -- Apply highlights initially
    apply_neotree_highlights()

    -- Reapply highlights when colorscheme changes
    local neotree_hl_group = vim.api.nvim_create_augroup("NeoTreeHighlights", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = neotree_hl_group,
      pattern = "*",
      callback = function()
        -- Schedule so we run after the new colorscheme finishes applying highlights
        vim.schedule(apply_neotree_highlights)
      end,
    })

    -- Also reapply when base46 reloads highlights (theme_switcher)
    vim.api.nvim_create_autocmd("User", {
      group = neotree_hl_group,
      pattern = "ThemeSwitched",
      callback = function()
        vim.schedule(apply_neotree_highlights)
      end,
    })
  end,
}
