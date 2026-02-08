return {
  "goolord/alpha-nvim",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")
    local utils = require("core.utils")

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

    _G._alpha_open_folder = open_folder_dialog
    _G._alpha_open_desktop = open_desktop
    _G._alpha_open_everything = open_everything

    dashboard.section.header.val = {
      "                                                     ",
      "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
      "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
      "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
      "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
      "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
      "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
      "                                                     ",
    }

    dashboard.section.buttons.val = {
      dashboard.button("e", "  New File", ":ene <BAR> startinsert<CR>"),
      dashboard.button("r", "  Recent Files", ":Telescope oldfiles<CR>"),
      dashboard.button("f", "  Find File", ":Telescope find_files<CR>"),
      dashboard.button("o", "󰝰  Open Folder", "<cmd>lua _alpha_open_folder()<CR>"),
      dashboard.button("d", "󰇄  Desktop", "<cmd>lua _alpha_open_desktop()<CR>"),
      dashboard.button("x", "󰓎  Everything", "<cmd>lua _alpha_open_everything()<CR>"),
      dashboard.button("s", "󰦛  Sessions", "<cmd>SessionManager load_session<CR>"),
      dashboard.button("-", "", ""), -- visual separator
      dashboard.button("c", "  Configuration", "<cmd>e $MYVIMRC | :cd %:p:h<CR>"),
      dashboard.button("l", "  Lazy", "<cmd>Lazy<CR>"),
      dashboard.button("q", "  Quit", ":qa<CR>"),
    }

    -- Deferred footer so lazy.nvim stats are accurate (startup is still running when alpha loads).
    dashboard.section.footer.val = ""
    dashboard.section.footer.opts.hl = "Type"

    alpha.setup(dashboard.opts)

    -- Show plugin load stats in the footer once lazy.nvim has finished.
    local function set_footer()
      local ok, lazy = pcall(require, "lazy")
      if not ok then return end
      local stats = lazy.stats()
      if stats.startuptime == 0 then return false end -- not ready yet
      dashboard.section.footer.val = "⚡ Neovim loaded "
        .. stats.count
        .. " plugins in "
        .. string.format("%.2f", stats.startuptime)
        .. "ms"
      pcall(function() require("alpha").redraw() end)
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
