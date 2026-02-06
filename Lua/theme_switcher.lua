local M = {}

local ok_path, Path = pcall(require, "plenary.path")

local function state_path()
  if not ok_path then
    return nil
  end
  return Path:new(vim.fn.stdpath("data"), "theme_state.json")
end

local function theme_defs()
  local ok, t = pcall(require, "theme_switcher.themes")
  if ok and t and type(t.get_all) == "function" then
    return t.get_all()
  end
  return {}
end

local function theme_def(theme_id)
  for _, t in ipairs(theme_defs()) do
    if t.id == theme_id then
      return t
    end
  end
  return nil
end

local function theme_display(theme_id)
  for _, t in ipairs(theme_defs()) do
    if t.id == theme_id then
      return t.name
    end
  end
  return theme_id
end

function M.current_id()
  return vim.g.current_theme or require("nvconfig").base46.theme
end

function M.current_display()
  return theme_display(M.current_id())
end

function M.save(theme_id)
  local p = state_path()
  if not p then
    return
  end
  local ok, data = pcall(vim.json.encode, { theme = theme_id })
  if not ok then
    return
  end
  p:write(data, "w")
end

function M.load_saved()
  local p = state_path()
  if not p or not p:exists() then
    return nil
  end

  local content = p:read()
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return nil
  end

  return decoded.theme
end

local function apply_theme(theme_id, opts)
  opts = opts or {}
  local persist = opts.persist ~= false
  local preview = opts.preview == true

  local def = theme_def(theme_id)
  local is_external = def and def.kind == "colorscheme"

  -- External colorschemes: apply them directly and don't let base46 override them.
  if is_external then
    pcall(function()
      local nv = require("nvconfig")
      nv.base46.transparency = false
    end)

    vim.g.current_theme = theme_id

    local old_lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true

    vim.schedule(function()
      local ok = pcall(vim.cmd, "colorscheme " .. theme_id)
      if not ok then
        vim.notify("Colorscheme not found: " .. theme_id, vim.log.levels.WARN)
      end

      pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "ThemeSwitched" })

      if not preview then
        pcall(function()
          require("lualine").refresh()
        end)
      end

      vim.o.lazyredraw = old_lazyredraw

      if persist then
        M.save(theme_id)
      end

      if not preview then
        pcall(vim.cmd, "redraw")
      end
    end)

    return
  end

  local nv = require("nvconfig")
  nv.base46.theme = theme_id

  -- Solid backgrounds for "normal" themes; keep neon_commit as-is.
  nv.base46.transparency = (theme_id == "neon_commit")

  local ok_base46, base46 = pcall(require, "base46")
  if not ok_base46 then
    vim.notify("base46 not available (" .. tostring(base46) .. ")", vim.log.levels.ERROR)
    return
  end

  vim.g.current_theme = theme_id

  local old_lazyredraw = vim.o.lazyredraw
  vim.o.lazyredraw = true

  vim.schedule(function()
    -- If a matching :colorscheme exists (e.g. external themes), apply it.
    -- base46 highlight loading below is still the primary mechanism.
    pcall(vim.cmd, "colorscheme " .. theme_id)

    base46.load_all_highlights()

    -- Notify listeners (neo-tree, statusline, etc.) that theme highlights changed.
    pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "ThemeSwitched" })

    if not preview then
      pcall(function()
        require("lualine").refresh()
      end)
    end

    vim.o.lazyredraw = old_lazyredraw

    if persist then
      M.save(theme_id)
    end

    -- Avoid forcing redraw during preview to reduce flashing.
    if not preview then
      pcall(vim.cmd, "redraw")
    end
  end)
end

function M.apply(theme_id, opts)
  opts = opts or {}
  apply_theme(theme_id, opts)
end

function M.apply_saved()
  local saved = M.load_saved()
  apply_theme(saved or require("nvconfig").base46.theme, { persist = false, preview = false })
end

function M.open_picker()
  local ok, picker = pcall(require, "theme_switcher.picker")
  if not ok or not picker or type(picker.open) ~= "function" then
    vim.notify("Theme picker not available", vim.log.levels.ERROR)
    return
  end

  picker.open()
end

function M.setup()
  -- Load previously selected theme early
  pcall(M.apply_saved)

  -- Keymap
  vim.keymap.set("n", "<leader>th", function()
    M.open_picker()
  end, { desc = "Theme switcher" })
end

return M
