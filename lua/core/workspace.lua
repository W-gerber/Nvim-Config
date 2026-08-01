-- Workspace handling: makes "open folder" behave like an IDE workspace.
-- The workspace root is simply Neovim's cwd; opening a folder cds into it,
-- so Telescope, Neo-tree, grep, LSP root detection etc. all follow along.

local M = {}
local utils = require("core.utils")

local function normalize(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end
  local absolute = vim.fn.fnamemodify(path, ":p"):gsub("[\\/]+$", "")
  return vim.fs.normalize(absolute)
end

--- Current workspace root (always the cwd).
---@return string
function M.root() return normalize(vim.fn.getcwd()) or vim.fn.getcwd() end

--- Short display name for the current workspace (folder name).
---@return string
function M.label()
  local root = M.root()
  if root == normalize(utils.desktop) then
    return utils.desktop_label
  end
  if root == normalize(utils.everything) then
    return utils.everything_label
  end
  if root == normalize(utils.home) then
    return "Home"
  end
  local name = vim.fn.fnamemodify(root, ":t")
  return name ~= "" and name or root
end

--- Open a folder as the workspace: cd into it, root the explorer there,
--- and notify anything listening (User WorkspaceChanged).
---@param dir string
---@param opts? { explorer?: boolean }  explorer=false skips opening neo-tree
---@return boolean ok
function M.open(dir, opts)
  opts = opts or {}
  dir = normalize(dir)

  if not dir or vim.fn.isdirectory(dir) == 0 then
    vim.notify("Can't open workspace — folder not found: " .. tostring(dir), vim.log.levels.WARN)
    return false
  end

  local ok, err = pcall(vim.cmd.cd, vim.fn.fnameescape(dir))
  if not ok then
    vim.notify("Could not open workspace: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  if opts.explorer ~= false then
    pcall(function() require("neo-tree.command").execute({ action = "show", dir = dir }) end)
  end

  vim.api.nvim_exec_autocmds("User", {
    pattern = "WorkspaceChanged",
    data = { root = dir },
  })

  vim.notify("Workspace: " .. M.label(), vim.log.levels.INFO)
  return true
end

--- Native folder picker (Windows), with a prompt fallback elsewhere.
---@return string|nil dir absolute path, or nil if cancelled
function M.pick_folder()
  local dir = ""
  local cancelled = false

  if vim.fn.has("win32") == 1 then
    -- Print the chosen path behind a marker so we can pick it out even if
    -- PowerShell mixes in warnings/CLIXML noise on the same streams.
    local marker = "NVIM_PICKED>"
    local ps = table.concat({
      "Add-Type -AssemblyName System.Windows.Forms;",
      "$f = New-Object System.Windows.Forms.FolderBrowserDialog;",
      "$f.Description = 'Open Folder as Workspace';",
      "$f.ShowNewFolderButton = $true;",
      "if ($f.ShowDialog() -eq 'OK') { Write-Output ('" .. marker .. "' + $f.SelectedPath) }",
    }, " ")

    -- Prefer pwsh (PowerShell 7): its FolderBrowserDialog is the modern
    -- Vista-style picker; Windows PowerShell falls back to the classic tree.
    -- -STA is required for Windows Forms dialogs.
    local shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
    local lines = vim.fn.systemlist({ shell, "-NoProfile", "-STA", "-Command", ps }) or {}

    for _, line in ipairs(lines) do
      local picked = line:match(vim.pesc(marker) .. "%s*(.-)%s*$")
      if picked and picked ~= "" then
        dir = picked
        break
      end
    end

    -- Dialog ran fine but produced no path: the user hit Cancel.
    if dir == "" and vim.v.shell_error == 0 then
      cancelled = true
    end
  end

  -- Fallback prompt only when no native dialog was available/working.
  if dir == "" and not cancelled then
    dir = vim.fn.input("Open Folder: ", M.root() .. "/", "dir")
  end

  -- Strip stray quotes (e.g. a path pasted as "C:\...").
  dir = vim.trim(dir):gsub('^"(.-)"$', "%1")

  if dir == "" then
    return nil
  end

  return normalize(dir)
end

--- Show the folder picker and open the chosen folder as the workspace.
function M.open_dialog()
  local dir = M.pick_folder()
  if dir then
    M.open(dir)
  end
end

--- On startup with no file arguments, GUI launches often land in an
--- unhelpful cwd (home, system32). Fall back to the Everything folder
--- so pickers stay fast and predictable.
function M.apply_startup_default()
  if vim.fn.argc(-1) > 0 then
    return
  end

  local cwd = M.root()
  local system_root = normalize(vim.env.SystemRoot or "C:/Windows")
  local unhelpful = cwd == normalize(utils.home)
    or (system_root and cwd:lower():sub(1, #system_root) == system_root:lower())

  if unhelpful and vim.fn.isdirectory(utils.everything) == 1 then
    pcall(vim.cmd.cd, vim.fn.fnameescape(utils.everything))
  end
end

return M
