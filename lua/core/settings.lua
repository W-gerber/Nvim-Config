-- core/settings.lua
-- Editor options and feature flags

local M = {}

-- Basic options
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.undofile = true

-- Providers (disable those not available to avoid noisy :checkhealth warnings)
-- We only enable a provider if its host executable is found. This keeps Windows
-- setups clean where perl/ruby are often missing.
local provider_map = {
	python3 = { exe = (vim.fn.has("win32") == 1) and "python" or "python3" },
	ruby = { exe = "ruby" },
	perl = { exe = "perl" },
	node = { exe = "node" },
}
for name, meta in pairs(provider_map) do
	if vim.fn.executable(meta.exe) == 0 then
		vim.g["loaded_" .. name .. "_provider"] = 0 -- disable missing provider
	end
end

-- lsd fallback (pretty ls). Some configs / habits may rely on `lsd`; we provide
-- a unified :Ls command that picks the first available command among lsd, ls, dir.
-- This avoids errors on Windows where only `dir` exists in cmd.exe.
local function detect_ls()
	if vim.fn.executable("lsd") == 1 then return "lsd" end
	if vim.fn.executable("ls") == 1 then return "ls" end
	-- On Windows, fall back to internal shell built-in 'dir'
	return (vim.fn.has("win32") == 1) and "dir" or "ls"
end
vim.g._ls_cmd = detect_ls()

vim.api.nvim_create_user_command("Ls", function(opts)
	local cmd = vim.g._ls_cmd .. (opts.args ~= '' and (' ' .. opts.args) or '')
	-- Use bang to allow paging; on Windows 'dir' just runs inline.
	vim.cmd('!' .. cmd)
end, { nargs = '*', complete = 'file', desc = 'List directory using lsd/ls/dir fallback' })

-- Glassy UI adjustments kept (Tokyo Neon Skyline theme relies on these)

-- Visual glass effect defaults
vim.opt.winblend = 30
vim.opt.pumblend = 30
vim.opt.laststatus = 3
vim.opt.cmdheight = 1

-- GUI-specific hints (Neovide, etc.)
vim.g.neovide_transparency = 0.85

return M
