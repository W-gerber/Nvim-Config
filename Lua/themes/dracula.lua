-- Dracula wrapper theme (uses base46's chadracula as a base)
local chadracula = require("base46.themes.chadracula")
local M = vim.deepcopy(chadracula)

M = require("base46").override_theme(M, "dracula")

return M
