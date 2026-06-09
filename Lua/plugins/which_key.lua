return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer keymaps",
      mode = "n",
    },
  },
  config = function()
    local ok, wk = pcall(require, "which-key")
    if not ok then
      return
    end

    local ui = require("core.ui")
    local utils = require("core.utils")

    local function apply_which_key_highlights()
      local palette = ui.float_palette()
      local border_palette = ui.utility_palette()
      local hl = vim.api.nvim_set_hl

      hl(0, "WhichKeyNormal", { bg = "NONE", fg = palette.fg })
      hl(0, "WhichKeyBorder", { bg = "NONE", fg = border_palette.border })
      hl(0, "WhichKeyTitle", { bg = "NONE", fg = palette.fg, bold = true })
      hl(0, "WhichKey", { bg = "NONE", fg = palette.fg, bold = true })
      hl(0, "WhichKeySeparator", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyGroup", { bg = "NONE", fg = palette.fg, bold = true })
      hl(0, "WhichKeyDesc", { bg = "NONE", fg = palette.fg })
      hl(0, "WhichKeyValue", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIcon", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconAzure", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconBlue", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconCyan", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconGreen", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconGrey", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconOrange", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconPurple", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconRed", { bg = "NONE", fg = palette.muted })
      hl(0, "WhichKeyIconYellow", { bg = "NONE", fg = palette.muted })
    end

    apply_which_key_highlights()

    wk.setup({
      preset = "modern",
      delay = function(ctx)
        return ctx.plugin and 0 or 180
      end,
      triggers = {
        { "<leader>", mode = { "n", "v" } },
      },
      expand = 1,
      plugins = {
        presets = {
          windows = true,
          nav = true,
          z = true,
          g = true,
        },
        spelling = { enabled = false },
      },
      win = {
        border = "rounded",
        title = true,
        title_pos = "center",
        no_overlap = true,
        padding = { 1, 2 },
        wo = {
          winblend = 0,
        },
      },
      layout = {
        width = { min = 24, max = 40 },
        spacing = 4,
      },
      icons = {
        breadcrumb = "󰘍 ",
        separator = "󰜴",
        ellipsis = "…",
        mappings = true,
        colors = false,
        keys = {
          Space = "Neovim ",
          CR = "RET ",
          Esc = "ESC ",
          Tab = "TAB ",
        },
      },
      show_help = false,
      show_keys = false,
    })

    vim.keymap.set("n", "<leader>?", function()
      wk.show({ global = false })
    end, { desc = "Buffer keymaps", silent = true })

    local which_key_group = ui.create_augroup("WhichKeyThemeHighlights")
    ui.on_theme_change(which_key_group, apply_which_key_highlights)

    wk.add({
      -- Buffers
      { "<leader>?", desc = "Buffer keymaps", icon = "�" },
      { "<leader>b",  group = "Buffers", icon = "󰓩" },
      { "<leader>bn", desc = "New buffer", icon = "" },
      { "<leader>bc", desc = "Close buffer", icon = "󰅖" },
      { "<leader>bC", desc = "Force close buffer", icon = "󱎘" },
      { "<leader>bo", desc = "Close other buffers", icon = "󰈩" },
      { "<leader>bO", desc = "Force close other buffers", icon = "󰈩" },

      -- Diagnostics / LSP helpers
      { "<leader>c",  group = "Copilot", icon = "" },
      { "<leader>d",  desc = "Line diagnostics", icon = "󰒡" },

      -- File explorer
      { "<leader>e",  desc = "Explorer", icon = "�" },

      -- Telescope
      { "<leader>f",  group = "Find", icon = "󰍉" },
      { "<leader>ff", desc = "Files (" .. utils.everything_label .. ")", icon = "󰈞" },
      { "<leader>fg", desc = "Grep (" .. utils.everything_label .. ")", icon = "󰈬" },
      { "<leader>fb", desc = "Open buffers", icon = "�" },
      { "<leader>fh", desc = "Help tags", icon = "�" },

      -- Git (gitsigns)
      { "<leader>g",  group = "Git", icon = "�" },
      { "<leader>gs", desc = "Stage hunk", icon = "" },
      { "<leader>gr", desc = "Reset hunk", icon = "󰕌" },
      { "<leader>gS", desc = "Stage buffer", icon = "󰐕" },
      { "<leader>gu", desc = "Undo stage hunk", icon = "" },
      { "<leader>gp", desc = "Preview hunk", icon = "�" },
      { "<leader>gb", desc = "Blame line", icon = "�" },

      -- Lazygit wrapper
      { "<leader>l",  group = "Lazygit", icon = "�" },
      { "<leader>lg", desc = "Open Lazygit", icon = "󰖳" },
      { "<leader>lG", desc = "Current file in Lazygit", icon = "�" },

      -- Window management
      { "<leader>q",  desc = "Close window", icon = "󰅖" },

      -- Sessions
      { "<leader>s",  group = "Sessions", icon = "󱂬" },
      { "<leader>sl", desc = "Load session", icon = "�" },
      { "<leader>ss", desc = "Save session", icon = "" },
      { "<leader>sd", desc = "Delete session", icon = "�" },

      -- Tools / misc
      { "<leader>t",  group = "Tools", icon = "󱁤" },
      { "<leader>tt", desc = "Toggle terminal", icon = "" },

      -- Trouble (diagnostics UI)
      { "<leader>x",  group = "Trouble", icon = "󱍼" },
      { "<leader>xx", desc = "Diagnostics", icon = "" },
      { "<leader>xX", desc = "Buffer diagnostics", icon = "󰈙" },
      { "<leader>xs", desc = "Symbols", icon = "󰘦" },
      { "<leader>xr", desc = "LSP list", icon = "" },
      { "<leader>xL", desc = "Location list", icon = "�" },
      { "<leader>xQ", desc = "Quickfix list", icon = "󰁨" },

      -- Theme switcher
      { "<leader>th", desc = "Theme picker", icon = "" },
    })
  end,
}
