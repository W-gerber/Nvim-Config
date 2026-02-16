-- Dracula wrapper theme (uses base46's chadracula as a base)
local ok_chad, chadracula = pcall(require, "base46.themes.chadracula")
if not ok_chad then return {} end
local M = vim.deepcopy(chadracula)

local ok_base46, base46 = pcall(require, "base46")
if ok_base46 then
  M = base46.override_theme(M, "dracula")
end

return M
