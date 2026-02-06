return {
  "goolord/alpha-nvim",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Dashboard button callbacks must be global (used via :lua ...)
    _G.OpenFolderDialog = function()
      local path = ""

      -- Prefer the native Windows folder picker (VS Code style).
      if vim.fn.has("win32") == 1 then
        local ps = table.concat({
          "Add-Type -AssemblyName System.Windows.Forms;",
          "$d = New-Object System.Windows.Forms.FolderBrowserDialog;",
          "$d.Description = 'Select a folder';",
          "$d.ShowNewFolderButton = $true;",
          "if ($d.ShowDialog() -eq 'OK') { $d.SelectedPath }",
        }, " ")

        -- `system()` returns the output (folder path) or empty.
        path = (vim.fn.system({ "powershell", "-NoProfile", "-Command", ps }) or ""):gsub("\r?\n", "")
      end

      -- Fallback: Neovim's built-in directory prompt.
      if path == "" then
        path = vim.fn.input("Open Folder: ", "", "dir")
      end

      if path ~= "" then
        -- Open in Windows Explorer so you can use "Open with" (VS Code, etc.)
        if vim.fn.has("win32") == 1 then
          pcall(vim.fn.jobstart, { "explorer.exe", path }, { detach = true })
        end

        -- Also switch Neovim to that folder + open the Explorer.
        pcall(vim.cmd, "cd " .. vim.fn.fnameescape(path))
        pcall(function()
          require("neo-tree.command").execute({ toggle = true, dir = path })
        end)
      end
    end

    _G.OpenDesktop = function()
      local desktop_path = "C:/Users/wgerb/Desktop"
      require("neo-tree.command").execute({ toggle = true, dir = desktop_path })
    end

    _G.OpenEverything = function()
      local everything_path = "C:/Users/wgerb/Desktop/Everything"
      require("neo-tree.command").execute({ toggle = true, dir = everything_path })
    end

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
      dashboard.button("o", "󰝰  Open Folder", ":lua OpenFolderDialog()<CR>"),
      dashboard.button("d", "󰇄  Desktop", ":lua OpenDesktop()<CR>"),
      dashboard.button("x", "󰓎  Everything", ":lua OpenEverything()<CR>"),
      dashboard.button("s", "󰦛  Sessions", "<cmd>SessionManager load_session<CR>"),
      dashboard.button("-", "", ""), -- visual separator
      dashboard.button("c", "  Configuration", "<cmd>e $MYVIMRC | :cd %:p:h<CR>"),
      dashboard.button("l", "  Lazy", "<cmd>Lazy<CR>"),
      dashboard.button("q", "  Quit", ":qa<CR>"),
    }

    local stats = require("lazy").stats()
    dashboard.section.footer.val = "⚡ Neovim loaded " .. stats.count .. " plugins in " .. string.format("%.2f", stats.startuptime) .. "ms"
    dashboard.section.footer.opts.hl = "Type"

    alpha.setup(dashboard.opts)
  end,
}
