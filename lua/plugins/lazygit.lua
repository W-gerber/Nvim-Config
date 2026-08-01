-- Lazygit, in a floating window. Provides :LazyGit and friends.

--- Make sure `lazygit` is reachable, adding winget's install location to PATH
--- when it is installed but not exported (which is winget's default).
---@return boolean available
local function ensure_lazygit()
  if vim.fn.executable("lazygit") == 1 then
    return true
  end

  -- winget installs to a versioned package directory that it does not put on
  -- PATH. This lookup is Windows-only; elsewhere a missing binary is simply
  -- a missing binary.
  if vim.fn.has("win32") == 1 then
    local packages = vim.fs.joinpath(vim.env.LOCALAPPDATA or "", "Microsoft", "WinGet", "Packages")

    if vim.fn.isdirectory(packages) == 1 then
      local matches = vim.fn.glob(packages .. "/JesseDuffield.lazygit*/lazygit.exe", false, true)
      local exe = matches[1]

      if exe and vim.fn.filereadable(exe) == 1 then
        vim.env.PATH = vim.fn.fnamemodify(exe, ":h") .. ";" .. (vim.env.PATH or "")
        return true
      end
    end
  end

  vim.notify(
    "lazygit not found on PATH.\nInstall it and restart Neovim:\n"
      .. "  winget install JesseDuffield.lazygit\n"
      .. "  brew install lazygit",
    vim.log.levels.ERROR,
    { title = "Lazygit" }
  )

  return false
end

--- Run a Lazygit command, but only once the binary is known to exist.
---@param command string
---@return fun()
local function guarded(command)
  return function()
    if ensure_lazygit() then
      vim.cmd(command)
    end
  end
end

return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentDirectory",
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>lg", guarded("LazyGit"), desc = "Open Lazygit" },
    { "<leader>lG", guarded("LazyGitCurrentFile"), desc = "Lazygit: current file" },
  },
  init = function()
    vim.g.lazygit_floating_window_use_plenary = 1
    vim.g.lazygit_floating_window_border_chars =
      { "\u{256d}", "\u{2500}", "\u{256e}", "\u{2502}", "\u{256f}", "\u{2500}", "\u{2570}", "\u{2502}" }
  end,
}
