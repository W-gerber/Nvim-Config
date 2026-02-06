-- Lazygit plugin spec for lazy.nvim
-- Provides :LazyGit and related commands

return {
	"kdheepak/lazygit.nvim",
	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentDirectory",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	keys = {
		{ "<leader>lg", function()
				local exe = vim.fn.exepath("lazygit")
				if exe == "" then
					local winget_exe = (vim.env.LOCALAPPDATA or "") .. "\\Microsoft\\WinGet\\Packages\\JesseDuffield.lazygit_Microsoft.Winget.Source_8wekyb3d8bbwe\\lazygit.exe"
					if vim.fn.filereadable(winget_exe) == 1 then
						exe = winget_exe
						vim.env.PATH = vim.fn.fnamemodify(winget_exe, ":h") .. ";" .. (vim.env.PATH or "")
					end
				end
				if exe == "" then
					vim.notify("lazygit not found. Open a new terminal/Neovim after installing with winget.", vim.log.levels.ERROR)
					return
				end
				vim.cmd("LazyGit")
			end, desc = "Open Lazygit" },
		{ "<leader>lG", function()
				local exe = vim.fn.exepath("lazygit")
				if exe == "" then
					local winget_exe = (vim.env.LOCALAPPDATA or "") .. "\\Microsoft\\WinGet\\Packages\\JesseDuffield.lazygit_Microsoft.Winget.Source_8wekyb3d8bbwe\\lazygit.exe"
					if vim.fn.filereadable(winget_exe) == 1 then
						exe = winget_exe
						vim.env.PATH = vim.fn.fnamemodify(winget_exe, ":h") .. ";" .. (vim.env.PATH or "")
					end
				end
				if exe == "" then
					vim.notify("lazygit not found. Open a new terminal/Neovim after installing with winget.", vim.log.levels.ERROR)
					return
				end
				vim.cmd("LazyGitCurrentFile")
			end, desc = "Lazygit: current file" },
	},
	init = function()
		vim.g.lazygit_floating_window_use_plenary = 1
	end,
}

