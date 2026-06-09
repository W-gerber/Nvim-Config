return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local alpha_utils = require("alpha.utils")
    local dashboard = require("alpha.themes.dashboard")
    local ui = require("core.ui")
    local utils = require("core.utils")

    local logo = {
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
    local logo_widths = { 44, 50, 43, 66, 68, 68, 69, 70, 70 }
    local logo_hl = {}
    local logo_groups = {
      "AlphaLogo1",
      "AlphaLogo2",
      "AlphaLogo3",
      "AlphaLogo4",
      "AlphaLogo5",
      "AlphaLogo6",
      "AlphaLogo7",
      "AlphaLogo8",
      "AlphaLogo9",
    }

    for index, width in ipairs(logo_widths) do
      logo_hl[index] = { { logo_groups[index], 1, width } }
    end

    local function redraw_alpha()
      dashboard.section.header.opts.hl = alpha_utils.charhl_to_bytehl(logo_hl, logo, false)
      pcall(function()
        require("alpha").redraw()
      end)
    end

    local function apply_alpha_highlights()
      local palette = ui.float_palette()
      local ok_theme, theme = pcall(require, "theme")
      local neon = ok_theme and theme and theme.neon or {}
      local logo_gradient = {
        neon.cyan or palette.accent,
        "#76deff",
        "#55ceff",
        neon.blue or "#1e90ff",
        "#1b7ae6",
        "#1665c4",
        "#12519f",
        "#0d3c78",
        "#082850",
      }
      local hl = vim.api.nvim_set_hl
      local button_text = vim.o.background == "light" and "#21456f" or "#d7e6f8"

      hl(0, "AlphaButtons", { fg = button_text, bold = true })
      hl(0, "AlphaShortcut", { fg = logo_gradient[1], bold = true })
      hl(0, "AlphaFooter", { fg = palette.muted })
      hl(0, "AlphaLogo1", { fg = logo_gradient[1] })
      hl(0, "AlphaLogo2", { fg = logo_gradient[2] })
      hl(0, "AlphaLogo3", { fg = logo_gradient[3] })
      hl(0, "AlphaLogo4", { fg = logo_gradient[4] })
      hl(0, "AlphaLogo5", { fg = logo_gradient[5] })
      hl(0, "AlphaLogo6", { fg = logo_gradient[6] })
      hl(0, "AlphaLogo7", { fg = logo_gradient[7] })
      hl(0, "AlphaLogo8", { fg = logo_gradient[8] })
      hl(0, "AlphaLogo9", { fg = logo_gradient[9] })
    end

    local function dashboard_button(shortcut, icon, label, command)
      local button = dashboard.button(shortcut, icon .. "  " .. label, command)

      button.opts.hl = "AlphaButtons"
      button.opts.hl_shortcut = "AlphaShortcut"

      return button
    end

    -- Alpha keymaps are buffer-local and need a :lua command string, so we
    -- expose these callbacks as _G with a prefix to keep the namespace tidy.
    local function open_folder_dialog()
      local path = ""

      -- Open the native Windows file picker (OpenFileDialog) so the user
      -- can browse with their default file explorer (e.g. the Files app).
      if vim.fn.has("win32") == 1 then
        local ps = table.concat({
          "Add-Type -AssemblyName System.Windows.Forms;",
          "$f = New-Object System.Windows.Forms.OpenFileDialog;",
          "$f.Title = 'Open a file in Neovim';",
          "$f.Filter = 'All files (*.*)|*.*';",
          "$f.Multiselect = $false;",
          "if ($f.ShowDialog() -eq 'OK') { $f.FileName }",
        }, " ")

        path = (vim.fn.system({ "powershell", "-NoProfile", "-Command", ps }) or ""):gsub("\r?\n", "")
      end

      -- Fallback: Neovim's built-in file prompt.
      if path == "" then
        path = vim.fn.input("Open File: ", "", "file")
      end

      if path ~= "" then
        pcall(vim.cmd, "edit " .. vim.fn.fnameescape(path))
        local dir = vim.fn.fnamemodify(path, ":h")
        pcall(vim.cmd, "cd " .. vim.fn.fnameescape(dir))
        pcall(function()
          require("neo-tree.command").execute({ toggle = true, dir = dir })
        end)
      end
    end

    local function open_desktop()
      require("neo-tree.command").execute({ toggle = true, dir = utils.desktop })
    end

    local function open_everything()
      require("neo-tree.command").execute({ toggle = true, dir = utils.everything })
    end

    local function open_recent_files()
      require("telescope.builtin").oldfiles({
        prompt_title = "Recent Files",
      })
    end

    local function find_files_in_root()
      require("telescope.builtin").find_files({
        cwd = utils.everything,
        hidden = true,
        no_ignore = true,
        prompt_title = "Find Files • " .. utils.everything_label,
      })
    end

    _G._alpha_open_folder = open_folder_dialog
    _G._alpha_open_desktop = open_desktop
    _G._alpha_open_everything = open_everything
    _G._alpha_open_recent_files = open_recent_files
    _G._alpha_find_files = find_files_in_root

    apply_alpha_highlights()

    dashboard.section.header.val = logo
    dashboard.section.header.opts.position = "center"
    dashboard.section.header.opts.hl = alpha_utils.charhl_to_bytehl(logo_hl, logo, false)

    dashboard.section.buttons.val = {
      dashboard_button("e", "", "New File", ":ene <BAR> startinsert<CR>"),
      dashboard_button("r", "", "Recent Files", "<cmd>lua _alpha_open_recent_files()<CR>"),
      dashboard_button("f", "", "Find File", "<cmd>lua _alpha_find_files()<CR>"),
      dashboard_button("o", "󰝰", "Open Folder", "<cmd>lua _alpha_open_folder()<CR>"),
      dashboard_button("d", "󰇄", utils.desktop_label, "<cmd>lua _alpha_open_desktop()<CR>"),
      dashboard_button("x", "󰓎", utils.everything_label, "<cmd>lua _alpha_open_everything()<CR>"),
      dashboard_button("s", "󰦛", "Sessions", "<cmd>SessionManager load_session<CR>"),
      { type = "padding", val = 1 },
      dashboard_button("c", "", "Configuration", "<cmd>e $MYVIMRC | :cd %:p:h<CR>"),
      dashboard_button("l", "", "Lazy", "<cmd>Lazy<CR>"),
      dashboard_button("q", "", "Quit", ":qa<CR>"),
    }
    dashboard.section.buttons.opts.hl = "AlphaButtons"
    dashboard.section.buttons.opts.hl_shortcut = "AlphaShortcut"
    dashboard.section.buttons.opts.spacing = 1
    dashboard.section.buttons.opts.position = "center"

    -- Deferred footer so lazy.nvim stats are accurate (startup is still running when alpha loads).
    dashboard.section.footer.val = ""
    dashboard.section.footer.opts.hl = "AlphaFooter"
    dashboard.section.footer.opts.position = "center"

    dashboard.opts.layout[1].val = 4

    alpha.setup(dashboard.opts)

    local alpha_group = ui.create_augroup("AlphaThemeHighlights")
    ui.on_theme_change(alpha_group, function()
      apply_alpha_highlights()
      redraw_alpha()
    end)

    -- Show plugin load stats in the footer once lazy.nvim has finished.
    local function set_footer()
      local ok, lazy = pcall(require, "lazy")
      if not ok then return end
      local stats = lazy.stats()
      if stats.startuptime == 0 then return false end -- not ready yet
      dashboard.section.footer.val = "⚡loaded "
        .. stats.count
        .. " plugins in "
        .. string.format("%.2f", stats.startuptime)
        .. " ms"
      redraw_alpha()
      return true
    end

    -- Try immediately (event may have already fired), then also listen for it.
    if not set_footer() then
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        once = true,
        callback = set_footer,
      })
    end
  end,
}
