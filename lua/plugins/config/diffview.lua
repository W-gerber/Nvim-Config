-- plugins/config/diffview.lua
local present, diffview = pcall(require, 'diffview')
if not present then return end

-- Disable Mercurial (hg) probing on Windows to avoid health warning since we only use Git.
diffview.setup({
	enhanced_diff_hl = true,
	vcs = { hg = { cmd = nil } }, -- explicitly disable hg
})
