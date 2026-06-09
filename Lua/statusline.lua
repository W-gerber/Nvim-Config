local ok_theme, theme = pcall(require, "theme")
local neon = (ok_theme and theme and theme.neon) or {
  cyan = "#00d7ff",
  hotpink = "#ff2d95",
  lime = "#b7ff3a",
  purple = "#9d7cff",
  orange = "#ff9e1b",
  white = "#ffffff",
  gray = "#808080",
  neon_yellow = "#CFFF04",
  blue = "#1e90ff",
  bg = "#080808",
}

local colors = {
  normal = "#082850",
  insert = neon.neon_yellow,
  visual = neon.hotpink,
  replace = "#ff5189",
  command = neon.cyan,
  terminal = neon.purple,
  panel = "#0b1220",
  panel_alt = "#0f1830",
  panel_soft = "#13203a",
  black = neon.bg or "#080808",
  white = neon.white or "#ffffff",
  muted = "#8a94aa",
  grey = "#303030",
  cyan = neon.cyan,
  lime = neon.lime,
  orange = neon.orange,
  hotpink = neon.hotpink,
  red = "#ff5189",
}

local rounded = { left = "", right = "" }

local function spacer(width)
  return {
    function()
      return string.rep(" ", width)
    end,
    color = { bg = "NONE" },
    padding = 0,
  }
end

local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if not gitsigns then
    return nil
  end

  return {
    added = gitsigns.added,
    modified = gitsigns.changed,
    removed = gitsigns.removed,
  }
end

local function lsp_client()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if not clients or vim.tbl_isempty(clients) then
    return ""
  end

  local names = {}
  for _, client in ipairs(clients) do
    if client.name ~= "copilot" and client.name ~= "null-ls" then
      names[#names + 1] = client.name
    end
  end

  if #names == 0 then
    return ""
  end

  return " " .. table.concat(names, ", ")
end

local function has_lsp_client()
  return lsp_client() ~= ""
end

local bubbles_theme = {
  normal = {
    a = { fg = colors.white, bg = colors.normal, gui = "bold" },
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  insert = {
    a = { fg = colors.black, bg = colors.insert, gui = "bold" },
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  visual = {
    a = { fg = colors.black, bg = colors.visual, gui = "bold" },
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  replace = {
    a = { fg = colors.black, bg = colors.replace, gui = "bold" },
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  command = {
    a = { fg = colors.black, bg = colors.command, gui = "bold" },
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  terminal = {
    a = { fg = colors.black, bg = colors.terminal, gui = "bold" },
    b = { fg = colors.white, bg = "NONE" },
    c = { fg = colors.white, bg = "NONE" },
  },
  inactive = {
    a = { fg = colors.muted, bg = "NONE" },
    b = { fg = colors.muted, bg = "NONE" },
    c = { fg = colors.muted, bg = "NONE" },
  },
}

require("lualine").setup({
  options = {
    theme = bubbles_theme,
    section_separators = { left = "", right = "" },
    component_separators = { left = " ", right = " " },
    globalstatus = true,
    always_divide_middle = true,
  },
  sections = {
    lualine_a = {
      spacer(2),
      { "mode", separator = rounded, padding = { left = 1, right = 1 } },
    },
    lualine_b = {
      {
        "branch",
        icon = "",
        separator = rounded,
        color = { fg = colors.cyan, bg = colors.panel },
        padding = { left = 1, right = 1 },
      },
      {
        "diff",
        source = diff_source,
        colored = true,
        diff_color = {
          added = { fg = colors.lime },
          modified = { fg = colors.cyan },
          removed = { fg = colors.red },
        },
        symbols = { added = " ", modified = " ", removed = " " },
        separator = rounded,
        color = { fg = colors.white, bg = colors.panel_alt },
        padding = { left = 1, right = 1 },
      },
      {
        "filename",
        path = 0,
        file_status = true,
        newfile_status = true,
        shorting_target = 40,
        symbols = {
          modified = " ●",
          readonly = " ",
          unnamed = "[No Name]",
          newfile = " ",
        },
        separator = rounded,
        color = { fg = colors.white, bg = colors.panel_soft },
        padding = { left = 1, right = 1 },
      },
    },
    lualine_c = {
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        sections = { "error", "warn", "info", "hint" },
        diagnostics_color = {
          error = { fg = colors.red },
          warn = { fg = colors.orange },
          info = { fg = colors.cyan },
          hint = { fg = colors.lime },
        },
        symbols = {
          error = " ",
          warn = " ",
          info = " ",
          hint = "󰌵 ",
        },
        update_in_insert = false,
        separator = rounded,
        color = { fg = colors.white, bg = colors.panel },
        padding = { left = 1, right = 1 },
      },
    },
    lualine_x = {
      {
        lsp_client,
        cond = has_lsp_client,
        separator = rounded,
        color = { fg = colors.white, bg = colors.panel_alt },
        padding = { left = 1, right = 1 },
      },
      {
        "filetype",
        colored = true,
        icon_only = false,
        separator = rounded,
        color = { fg = colors.white, bg = colors.panel_soft },
        padding = { left = 1, right = 1 },
      },
    },
    lualine_y = {
      {
        "progress",
        separator = rounded,
        color = { fg = colors.white, bg = colors.panel },
        padding = { left = 1, right = 1 },
      },
    },
    lualine_z = {
      spacer(2),
    },
  },
  inactive_sections = {
    lualine_a = { spacer(2) },
    lualine_b = {
      {
        "filename",
        path = 0,
        separator = rounded,
        color = { fg = colors.muted, bg = colors.panel },
        padding = { left = 1, right = 1 },
      },
    },
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {
      spacer(2),
    },
  },
  tabline = {},
  extensions = {},
})

local function apply_statusline_transparency()
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", fg = colors.white })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE", fg = colors.grey })
end

apply_statusline_transparency()

local sl_group = vim.api.nvim_create_augroup("StatuslineTransparency", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = sl_group,
  callback = apply_statusline_transparency,
})
