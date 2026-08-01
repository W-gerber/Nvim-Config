-- `:checkhealth core` — verifies the things this config actually depends on.
--
-- Neovim's built-in health checks cover Neovim; these cover the assumptions
-- made here: the external binaries that features shell out to, a working C
-- compiler for Treesitter (with the PATH-shadowing trap that costs the most
-- time to diagnose), and the state of the theme layer.

local M = {}

local start = vim.health.start
local ok = vim.health.ok
local warn = vim.health.warn
local error_ = vim.health.error
local info = vim.health.info

--- Report on an external program.
---@param name string
---@param opts { required?: boolean, reason: string, install?: string }
local function check_executable(name, opts)
  local path = vim.fn.exepath(name)

  if path ~= "" then
    ok(("`%s` found at %s"):format(name, path))
    return true
  end

  local message = ("`%s` not found — %s"):format(name, opts.reason)
  if opts.install then
    message = message .. "\n  Install: " .. opts.install
  end

  if opts.required then
    error_(message)
  else
    warn(message)
  end

  return false
end

local function check_versions()
  start("Neovim")

  if vim.fn.has("nvim-0.11") == 1 then
    ok("Neovim " .. tostring(vim.version()))
  else
    error_("Neovim 0.11+ is required (vim.lsp.config, vim.diagnostic.jump, 'winborder')")
  end

  info("Config root: " .. vim.fn.stdpath("config"))
  info("Data root:   " .. vim.fn.stdpath("data"))
end

local function check_core_tools()
  start("Core tools")

  check_executable("git", {
    required = true,
    reason = "lazy.nvim bootstraps and updates plugins with it",
    install = "https://git-scm.com",
  })

  check_executable("rg", {
    reason = "Telescope live grep (<leader>fg) and todo-comments search need ripgrep",
    install = "winget install BurntSushi.ripgrep.MSVC  |  brew install ripgrep",
  })

  check_executable("fd", {
    reason = "optional; Telescope falls back to a slower internal file walker without it",
    install = "winget install sharkdp.fd  |  brew install fd",
  })

  check_executable("lazygit", {
    reason = "<leader>lg opens Lazygit",
    install = "winget install JesseDuffield.lazygit  |  brew install lazygit",
  })
end

--- Treesitter needs a working C toolchain, and on Windows the usual failure is
--- not a missing compiler but a shadowed one: Git for Windows ships an older
--- mingw64 runtime, and if its bin directory precedes MSYS2's on PATH then
--- cc1.exe fails to load and gcc exits silently. lua/core/options.lua hoists
--- MSYS2 to the front to prevent that; this verifies it actually worked.
local function check_treesitter()
  start("Treesitter toolchain")

  local compiler
  for _, name in ipairs({ "cc", "gcc", "clang", "zig" }) do
    if vim.fn.executable(name) == 1 then
      compiler = name
      break
    end
  end

  if not compiler then
    error_(
      "No C compiler found — Treesitter parsers cannot be built.\n"
        .. "  Windows: install MSYS2 and `pacman -S mingw-w64-x86_64-gcc`\n"
        .. "  macOS:   xcode-select --install\n"
        .. "  Linux:   install gcc or clang from your package manager"
    )
    return
  end

  -- Actually compile something: presence on PATH proves nothing when the
  -- runtime DLLs beside it are the wrong ones.
  local out = vim.fs.joinpath(vim.fn.stdpath("cache"), "health-cc-probe")
  local result = vim
    .system({ compiler, "-o", out, "-x", "c", "-" }, {
      stdin = "int main(void){return 0;}",
      text = true,
    })
    :wait()

  if result.code == 0 then
    ok(("`%s` compiles successfully (%s)"):format(compiler, vim.fn.exepath(compiler)))
    pcall(vim.fn.delete, out)
  else
    error_(
      ("`%s` is on PATH but failed to compile a trivial program (exit %d).\n"):format(compiler, result.code)
        .. "  On Windows this usually means another toolchain's DLLs shadow it —\n"
        .. "  check that MSYS2's mingw64\\bin comes before Git's on $PATH.\n"
        .. "  stderr: "
        .. ((result.stderr or ""):gsub("%s+$", ""))
    )
  end

  -- Count on disk rather than via the runtimepath: nvim-treesitter is lazy, so
  -- its parser directory is not on 'rtp' until a buffer has opened.
  local seen = {}
  local roots = vim.api.nvim_get_runtime_file("parser", true)
  table.insert(roots, vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "nvim-treesitter", "parser"))

  for _, root in ipairs(roots) do
    for _, file in ipairs(vim.fn.glob(root .. "/*", false, true)) do
      seen[vim.fn.fnamemodify(file, ":t:r")] = true
    end
  end

  info(("%d Treesitter parsers installed"):format(vim.tbl_count(seen)))

  -- Stale clone directories left behind by an interrupted `:TSInstall` block
  -- every later install with "destination path already exists".
  local data = vim.fn.stdpath("data")
  local stale = vim.fn.glob(data .. "/tree-sitter-*", false, true)
  if #stale > 0 then
    warn(
      ("%d leftover tree-sitter clone director%s in %s.\n"):format(#stale, #stale == 1 and "y" or "ies", data)
        .. "  These block new parser installs with 'destination path already exists'.\n"
        .. "  Remove them and retry `:TSUpdate`."
    )
  else
    ok("No stale tree-sitter clone directories")
  end
end

--- Which formatters and linters are actually available.
---
--- Both layers treat a missing tool as a non-event — conform skips a formatter
--- it cannot run, and nvim-lint filters unavailable linters out before it fires
--- (see plugins/lint.lua) — which is the right behaviour and also means nothing
--- ever tells you *why* a filetype isn't being formatted. This does.
local function check_tooling()
  start("Formatters and linters")

  --- Distinct tool names across a `{ [filetype] = { "a", "b" } }` table.
  ---@param by_ft table<string, string[]>
  ---@return string[]
  local function tool_names(by_ft)
    local seen, names = {}, {}

    for _, tools in pairs(by_ft) do
      for key, tool in pairs(tools) do
        -- Skip option keys such as `stop_after_first = true`.
        if type(key) == "number" and type(tool) == "string" and not seen[tool] then
          seen[tool] = true
          names[#names + 1] = tool
        end
      end
    end

    table.sort(names)
    return names
  end

  --- Split `names` into what is runnable and what is not.
  ---@param names string[]
  ---@param resolve fun(name: string): string|nil the command to look for
  ---@return string[] available, string[] missing
  local function partition(names, resolve)
    local available, missing = {}, {}

    for _, name in ipairs(names) do
      local cmd = resolve(name)
      if cmd and vim.fn.executable(cmd) == 1 then
        available[#available + 1] = name
      elseif cmd then
        missing[#missing + 1] = name
      end
    end

    return available, missing
  end

  local function report(label, available, missing)
    if #available > 0 then
      ok(("%s available: %s"):format(label, table.concat(available, ", ")))
    end

    if #missing > 0 then
      info(("%s not installed (skipped silently): %s"):format(label, table.concat(missing, ", ")))
    end

    if #available == 0 and #missing == 0 then
      info(label .. ": nothing configured")
    end
  end

  -- conform.nvim
  local ok_conform, conform = pcall(require, "conform")
  if ok_conform then
    local names = vim.tbl_filter(
      -- The built-ins operate on the buffer directly; there is no binary.
      function(name) return name ~= "trim_whitespace" and name ~= "trim_newlines" end,
      tool_names(conform.formatters_by_ft or {})
    )

    local available, missing = partition(names, function(name)
      local info_ = conform.get_formatter_info and conform.get_formatter_info(name)
      return info_ and info_.command or name
    end)

    report("Formatters", available, missing)
    info("Format on save is " .. (vim.g.format_on_save and "on" or "off") .. " (<leader>cF toggles)")
  else
    info("conform.nvim is not loaded yet — open a file and re-run this check")
  end

  -- nvim-lint
  local ok_lint, lint = pcall(require, "lint")
  if ok_lint then
    local available, missing = partition(tool_names(lint.linters_by_ft or {}), function(name)
      local linter = lint.linters[name]
      -- A `cmd` that is a function resolves a project-local binary at call
      -- time; there is nothing to test for here.
      return type(linter) == "table" and type(linter.cmd) == "string" and linter.cmd or nil
    end)

    report("Linters", available, missing)
  else
    info("nvim-lint is not loaded yet — open a file and re-run this check")
  end
end

local function check_ui()
  start("UI")

  if vim.o.termguicolors then
    ok("'termguicolors' is on")
  else
    error_("'termguicolors' is off — themes will look wrong")
  end

  local theme = vim.g.current_theme
  if theme then
    ok("Active theme: " .. theme)
  else
    warn("No theme applied yet (theme_switcher.setup runs on the VeryLazy event)")
  end

  local cache = vim.g.base46_cache
  if cache and vim.fn.isdirectory(cache) == 1 then
    ok("base46 highlight cache: " .. cache)
  else
    warn("base46 cache directory is missing; run `:Theme` to rebuild it")
  end

  info("Glass background: " .. (vim.g.ui_transparent and "on" or "off"))
  info("A Nerd Font is required for icons: https://www.nerdfonts.com")
end

local function check_platform()
  start("Platform")

  if vim.fn.has("win32") == 1 then
    info("Windows")

    local shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
    ok(("Folder picker and media controls will use `%s`"):format(shell))

    if vim.fn.executable("pwsh") == 0 then
      warn("PowerShell 7 (`pwsh`) not found — the folder picker falls back to the legacy dialog")
    end
  else
    info(vim.fn.has("mac") == 1 and "macOS" or "Linux")
    warn("lua/core/music.lua is Windows-only; <leader>m mappings will report as unsupported")
  end
end

function M.check()
  check_versions()
  check_core_tools()
  check_tooling()
  check_treesitter()
  check_ui()
  check_platform()
end

return M
