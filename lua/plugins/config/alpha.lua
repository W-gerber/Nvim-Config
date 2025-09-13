-- plugins/config/alpha.lua
local has_alpha, alpha = pcall(require, "alpha")
if not has_alpha then return end

local dashboard = require("alpha.themes.dashboard")
local colors = require("ui.colors")

-- Helper functions for custom dashboard actions (Windows friendly)
local function OpenFileDialog()
  local file = vim.fn.input('Open file: ', '', 'file')
  if file ~= '' then vim.cmd('edit ' .. vim.fn.fnameescape(file)) end
end

local function OpenFolderDialog()
  local dir = vim.fn.input('Open directory: ', vim.fn.getcwd() .. '/', 'file')
  if dir ~= '' and vim.fn.isdirectory(dir) == 1 then
    vim.cmd('cd ' .. vim.fn.fnameescape(dir))
    pcall(vim.cmd, 'Neotree reveal')
  else
    vim.notify('Not a directory: ' .. dir, vim.log.levels.WARN)
  end
end

local function OpenDesktop()
  local desktop = (os.getenv('USERPROFILE') or '') .. '\\Desktop'
  if vim.fn.isdirectory(desktop) == 1 then
    vim.cmd('cd ' .. vim.fn.fnameescape(desktop))
    pcall(vim.cmd, 'Neotree reveal')
  else
    vim.notify('Desktop path not found: ' .. desktop, vim.log.levels.WARN)
  end
end

local function OpenEverything()
  -- Attempt to jump to the "Everything" workspace if it exists, else ~/Desktop
  local base = (os.getenv('USERPROFILE') or '') .. '\\Desktop\\Everything'
  if vim.fn.isdirectory(base) == 0 then
    base = (os.getenv('USERPROFILE') or '') .. '\\Desktop'
  end
  vim.cmd('cd ' .. vim.fn.fnameescape(base))
  pcall(vim.cmd, 'Neotree reveal')
end

-- Expose to global for the dashboard button calls
_G.OpenFileDialog = OpenFileDialog
_G.OpenFolderDialog = OpenFolderDialog
_G.OpenDesktop = OpenDesktop
_G.OpenEverything = OpenEverything

-- Get current time for dynamic greeting
local function get_greeting()
  local hour = tonumber(os.date("%H"))
  if hour < 6 then
    return " Good night"
  elseif hour < 12 then
    return " Good morning"
  elseif hour < 18 then
    return " Good afternoon"
  else
    return " Good evening"
  end
end

-- Get git info
local function get_git_info()
  local handle = io.popen("git branch --show-current 2>nul")
  if not handle then return "no repository" end
  local branch = handle:read("*a"):gsub("%s+", "")
  handle:close()
  
  if branch == "" then
    return "no repository"
  end
  
  -- Get commit count
  local commit_handle = io.popen("git rev-list --count HEAD 2>nul")
  local commits = "0"
  if commit_handle then
    commits = commit_handle:read("*a"):gsub("%s+", "")
    commit_handle:close()
  end
  
  return branch .. " (" .. commits .. " commits)"
end

-- Get recent project info
local function get_project_info()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ":t")
  return project_name
end

-- Beautiful Tokyo Neon Skyline header
dashboard.section.header.val = {
  "                                                     ",
  "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
  "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
  "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
  "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
  "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
  "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
  "                                                     ",

  "                                                     ",
}

-- Dynamic greeting section
dashboard.section.header.opts.hl = "Function"

-- Custom buttons with better icons and descriptions
dashboard.section.buttons.val = {
  dashboard.button('e', '  New File', '<cmd>ene <bar> startinsert<CR>'),
  dashboard.button('o', '󰈙  Open File', ':lua OpenFileDialog()<CR>'),
  dashboard.button('f', '  Find Files', '<cmd>Telescope find_files<CR>'),
  dashboard.button('r', '  Recent Files', '<cmd>Telescope oldfiles<CR>'),
  dashboard.button('p', '󰙅  Project Tree', '<cmd>Neotree toggle<CR>'),
  dashboard.button('-', '', ''), -- visual separator (noop)
  dashboard.button('w', '  Workspaces', '<cmd>Telescope projects<CR>'),
  dashboard.button('a', '󰝰  Open Folder', ':lua OpenFolderDialog()<CR>'),
  dashboard.button('d', '󰇄  Desktop', ':lua OpenDesktop()<CR>'),
  dashboard.button('x', '󰓎  Everything', ':lua OpenEverything()<CR>'),
  dashboard.button('s', '󰦛  Sessions', '<cmd>SessionManager load_session<CR>'),
  dashboard.button('=', '', ''), -- second separator
  dashboard.button('c', '  Configuration', '<cmd>e $MYVIMRC | :cd %:p:h<CR>'),
  dashboard.button('m', '  Mason', '<cmd>Mason<CR>'),
  dashboard.button('q', '  Quit', '<cmd>qa<CR>'),
}

-- Style the buttons
for _, button in ipairs(dashboard.section.buttons.val) do
  button.opts.hl = "Keyword"
  button.opts.hl_shortcut = "Function"
  button.opts.cursor = 3
  button.opts.width = 50
  button.opts.align_shortcut = "right"
  button.opts.position = "center"
end

-- Dynamic footer with system info
local function create_footer()
  local datetime = os.date("  %A, %B %d, %Y  •  %H:%M:%S")
  local version = "  Neovim " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch
  local project = "  Project: " .. get_project_info()
  local git_info = "  Git: " .. get_git_info()
  local greeting = get_greeting() .. ", " .. (os.getenv("USERNAME") or "Developer") .. "!"
  
  return {
    "",
    "╭─────────────────────────────────────────────────────────────────╮",
    "│                        " .. greeting .. "                       │",
    "├─────────────────────────────────────────────────────────────────┤",
    "│" .. datetime .. "                                               │",
    "│" .. version .. "                                                │", 
    "│" .. project .. "                                                │",
    "│" .. git_info .. "                                               │",
    "╰─────────────────────────────────────────────────────────────────╯",
    "",
   
  }
end

dashboard.section.footer.val = create_footer()
dashboard.section.footer.opts.hl = "Comment"

-- Custom layout with proper spacing
dashboard.config.layout = {
  { type = "padding", val = 2 },
  dashboard.section.header,
  { type = "padding", val = 2 },
  dashboard.section.buttons,
  { type = "padding", val = 1 },
  dashboard.section.footer,
}

-- Add some color customization
dashboard.section.header.opts.hl = "String"

-- Auto-update footer every second when dashboard is visible
local function update_dashboard()
  if vim.bo.filetype == "alpha" then
    dashboard.section.footer.val = create_footer()
    require("alpha").redraw()
  end
end

-- Create auto-update timer for dynamic content (only when dashboard is active)
local timer = nil
local function start_timer()
  if timer then return end
  timer = vim.loop.new_timer()
  timer:start(1000, 1000, vim.schedule_wrap(update_dashboard))
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

-- Setup alpha with our custom config
alpha.setup(dashboard.config)

-- Hide tabline and statusline on alpha buffer
vim.api.nvim_create_autocmd("User", {
  pattern = "AlphaReady",
  callback = function()
    vim.opt.showtabline = 0
    vim.opt.laststatus = 0
    start_timer()  -- Start the update timer when dashboard is shown
  end,
})

-- Restore tabline and statusline when leaving alpha
vim.api.nvim_create_autocmd("BufUnload", {
  buffer = 0,
  callback = function()
    vim.opt.showtabline = 2
    vim.opt.laststatus = 3
    stop_timer()  -- Stop the timer when leaving dashboard
  end,
})

-- Add some neon highlights for the dashboard
vim.api.nvim_create_autocmd("FileType", {
  pattern = "alpha",
  callback = function()
    vim.api.nvim_set_hl(0, "AlphaHeader", { fg = colors.neon.cyan, bold = true })
    vim.api.nvim_set_hl(0, "AlphaButtons", { fg = colors.neon.hotpink })
    vim.api.nvim_set_hl(0, "AlphaShortcut", { fg = colors.neon.lime, bold = true })
    vim.api.nvim_set_hl(0, "AlphaFooter", { fg = colors.neon.purple, italic = true })
  end,
})
