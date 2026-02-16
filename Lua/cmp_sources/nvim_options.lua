local M = {}

-- A small nvim-cmp source that provides Neovim option completions for `:set ...`
-- and attaches documentation (type/default/description) so the cmp docs window
-- can show VS Code–style inline help.

local function cmdline_is_set()
  if vim.fn.getcmdtype() ~= ":" then
    return false
  end
  local line = vim.fn.getcmdline() or ""
  -- Match: :set, :setl, :setlocal, :setg, :setglobal
  return line:match("^%s*set%w*%s+") ~= nil
end

local function to_markdown(option_name, info)
  local lines = {}

  local type_str = info and info.type or "option"
  local default_val = info and info.default

  local function fmt_default(v)
    if v == nil then
      return "(unknown)"
    end
    if type(v) == "boolean" then
      return v and "on" or "off"
    end
    if type(v) == "string" then
      if v == "" then
        return "\"\""
      end
      return string.format("%q", v)
    end
    return tostring(v)
  end

  -- Header
  table.insert(lines, string.format("**%s**", option_name))
  table.insert(lines, "")

  -- Metadata
  table.insert(lines, string.format("- Type: `%s`", type_str))
  table.insert(lines, string.format("- Default: `%s`", fmt_default(default_val)))

  if info and info.scope then
    table.insert(lines, string.format("- Scope: `%s`", info.scope))
  end

  table.insert(lines, "")

  -- Description (newer Neovim exposes `desc`/`shortdesc` in option info)
  local desc = (info and (info.desc or info.shortdesc))
  if desc and desc ~= "" then
    table.insert(lines, desc)
    table.insert(lines, "")
  end

  -- Usage notes
  if type(default_val) == "boolean" or type_str == "boolean" then
    table.insert(lines, "Usage:")
    table.insert(lines, string.format("- `:set %s`", option_name))
    table.insert(lines, string.format("- `:set no%s`", option_name))
  else
    table.insert(lines, "Usage:")
    table.insert(lines, string.format("- `:set %s=`", option_name))
  end

  return table.concat(lines, "\n")
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:is_available()
  return cmdline_is_set()
end

function M:get_debug_name()
  return "nvim_options"
end

-- Cache options list since it doesn't change at runtime.
local _cached_items = nil

function M:complete(_, callback)
  if _cached_items then
    callback({ items = _cached_items, isIncomplete = false })
    return
  end

  local ok, all = pcall(vim.api.nvim_get_all_options_info)
  if not ok or type(all) ~= "table" then
    callback({ items = {}, isIncomplete = false })
    return
  end

  local items = {}

  for name, info in pairs(all) do
    -- Keep it simple: only offer long option names (avoid short aliases clutter)
    if type(name) == "string" and #name > 1 then
      table.insert(items, {
        label = name,
        insertText = name,
        documentation = {
          kind = "markdown",
          value = to_markdown(name, info),
        },
      })
    end
  end

  _cached_items = items
  callback({ items = items, isIncomplete = false })
end

return M
