-- plugins/config/todo-comments.lua
local ok, todo = pcall(require, 'todo-comments')
if not ok then return end

todo.setup({ signs = true })
