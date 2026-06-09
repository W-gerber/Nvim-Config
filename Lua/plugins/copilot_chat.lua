return {
  "CopilotC-Nvim/CopilotChat.nvim",
  cmd = {
    "CopilotChat",
    "CopilotChatOpen",
    "CopilotChatClose",
    "CopilotChatToggle",
    "CopilotChatStop",
    "CopilotChatReset",
    "CopilotChatSave",
    "CopilotChatLoad",
    "CopilotChatPrompts",
    "CopilotChatModels",
    "CopilotChatLayout",
    "CopilotChatSide",
    "CopilotChatFloat",
    "CopilotChatChat",
    "CopilotChatAgent",
    "CopilotChatExplain",
    "CopilotChatReview",
    "CopilotChatFix",
    "CopilotChatOptimize",
    "CopilotChatDocs",
    "CopilotChatTests",
    "CopilotChatCommit",
  },
  keys = {
    { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "Copilot Chat: toggle", mode = "n" },
    { "<leader>cg", "<cmd>CopilotChatChat<cr>", desc = "Copilot Chat: standard mode", mode = "n" },
    { "<leader>cl", "<cmd>CopilotChatLayout<cr>", desc = "Copilot Chat: choose layout", mode = "n" },
    { "<leader>cs", "<cmd>CopilotChatSide<cr>", desc = "Copilot Chat: side panel", mode = "n" },
    { "<leader>cF", "<cmd>CopilotChatFloat<cr>", desc = "Copilot Chat: floating window", mode = "n" },
    { "<leader>cp", "<cmd>CopilotChatPrompts<cr>", desc = "Copilot Chat: prompts", mode = "n" },
    { "<leader>cm", "<cmd>CopilotChatModels<cr>", desc = "Copilot Chat: models", mode = "n" },
    { "<leader>cA", "<cmd>CopilotChatAgent<cr>", desc = "Copilot Chat: agent mode", mode = "n" },
    {
      "<leader>cq",
      function()
        local input = vim.fn.input("Copilot ask (buffer): ")
        if input == nil or input == "" then
          return
        end
        require("CopilotChat").ask("#buffer:active " .. input)
      end,
      desc = "Copilot: ask about buffer",
      mode = "n",
    },
    {
      "<leader>ce",
      function()
        local input = vim.fn.input("Copilot inline edit (selection): ")
        if input == nil or input == "" then
          return
        end
        require("CopilotChat").ask("#selection " .. input)
      end,
      desc = "Copilot: inline edit selection",
      mode = "v",
    },
  },
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "zbirenbaum/copilot.lua" },
  },
  config = function()
    local ok, chat = pcall(require, "CopilotChat")
    if not ok then
      return
    end

    local ui = require("core.ui")

    local function default_layout()
      if vim.o.columns >= 165 then
        return "float"
      end

      return "side"
    end

    local function normalize_layout(layout_name)
      if type(layout_name) ~= "string" then
        return nil
      end

      if layout_name == "vertical" then
        return "side"
      end

      if layout_name == "side" or layout_name == "float" then
        return layout_name
      end
    end

    local function layout_label(layout_name)
      if layout_name == "float" then
        return "floating window"
      end

      return "side panel"
    end

    local function mode_title(mode_name)
      if mode_name == "agent" then
        return "Copilot Agent"
      end

      return "Copilot Chat"
    end

    local current_mode = "chat"
    local current_layout = normalize_layout(vim.g.copilot_chat_layout) or default_layout()

    local base_opts = {
      headers = {
        user = " You",
        assistant = " Copilot",
        tool = " Tool",
      },
      separator = "━━",
      auto_fold = true,
      auto_insert_mode = true,
      show_help = true,
      show_folds = true,
      highlight_headers = true,
      highlight_selection = true,
      auto_follow_cursor = true,
      window = {},
    }

    local mode_opts = {
      chat = {
        tools = {},
        sticky = {},
        system_prompt = "COPILOT_INSTRUCTIONS",
      },
      agent = {
        tools = "copilot",
        sticky = { "@copilot" },
        system_prompt = table.concat({
          "You are operating in agent mode inside Neovim.",
          "Use workspace tools whenever you need more context instead of guessing.",
          "Prefer concrete, reviewable edits and unified diffs over high-level advice.",
          "Keep the plan short, execute the next useful step, and surface blockers directly.",
        }, "\n"),
      },
    }

    local function window_config(mode_name)
      local title = " " .. mode_title(mode_name) .. " "
      local footer

      if current_layout == "float" then
        footer = mode_name == "agent"
            and " agent tools on · switch layout with <leader>cl "
          or " clean floating chat · switch layout with <leader>cl "

        local width = math.floor(vim.o.columns * 0.56)
        local height = math.floor(vim.o.lines * 0.74)

        width = math.max(94, math.min(width, math.max(94, vim.o.columns - 10)))
        height = math.max(20, math.min(height, math.max(20, vim.o.lines - 6)))

        return {
          layout = "float",
          relative = "editor",
          width = width,
          height = height,
          row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1),
          col = math.max(2, math.floor((vim.o.columns - width) / 2)),
          border = "rounded",
          title = title,
          footer = footer,
          zindex = 70,
          blend = 0,
        }
      end

      return {
        layout = "vertical",
        width = vim.o.columns >= 190 and 62 or (vim.o.columns >= 150 and 56 or 0.42),
        height = vim.o.lines,
        border = "rounded",
        title = title,
        footer = " " .. layout_label(current_layout) .. " ",
        zindex = 60,
        blend = 0,
      }
    end

    local function mode_config(mode_name)
      local config = vim.tbl_deep_extend("force", {}, base_opts, mode_opts[mode_name] or mode_opts.chat)
      config.window = window_config(mode_name)
      return config
    end

    local function apply_chat_highlights()
      local palette = ui.float_palette()
      local hl = vim.api.nvim_set_hl

      hl(0, "CopilotChatNormal", { bg = palette.bg, fg = palette.fg })
      hl(0, "CopilotChatBorder", { bg = palette.bg, fg = palette.border })
      hl(0, "CopilotChatTitle", { bg = palette.bg, fg = palette.accent, bold = true })
      hl(0, "CopilotChatFooter", { bg = palette.bg, fg = palette.muted, italic = true })
      hl(0, "CopilotChatCursorLine", { bg = palette.selection_bg, fg = palette.selection_fg })
      hl(0, "CopilotChatHeader", { fg = palette.accent, bold = true })
      hl(0, "CopilotChatSeparator", { fg = palette.border })
      hl(0, "CopilotChatSelection", { bg = palette.selection_bg, fg = palette.selection_fg })
      hl(0, "CopilotChatStatus", { fg = palette.secondary, bold = true })
      hl(0, "CopilotChatHelp", { fg = palette.muted })
      hl(0, "CopilotChatResource", { fg = palette.secondary, bold = true })
      hl(0, "CopilotChatTool", { fg = palette.warning, bold = true })
      hl(0, "CopilotChatPrompt", { fg = palette.accent, bold = true })
      hl(0, "CopilotChatModel", { fg = palette.success, bold = true })
      hl(0, "CopilotChatUri", { fg = palette.secondary, underline = true })
      hl(0, "CopilotChatAnnotation", { bg = palette.selection_bg, fg = palette.muted })
      hl(0, "CopilotChatAnnotationHeader", { bg = palette.selection_bg, fg = palette.accent, bold = true })
      hl(0, "CopilotChatMuted", { bg = palette.bg, fg = palette.muted })
      hl(0, "CopilotChatWinBar", { bg = palette.bg, fg = palette.muted })
      hl(0, "CopilotChatWinBarIcon", { bg = palette.bg, fg = palette.secondary, bold = true })
      hl(0, "CopilotChatWinBarTitle", { bg = palette.bg, fg = palette.accent, bold = true })
      hl(0, "CopilotChatWinBarMeta", { bg = palette.bg, fg = palette.muted, italic = true })
    end

    apply_chat_highlights()

    local theme_group = ui.create_augroup("CopilotChatThemeHighlights")
    ui.on_theme_change(theme_group, apply_chat_highlights)

    local function build_winbar()
      return table.concat({
        "%#CopilotChatWinBar# ",
        "%#CopilotChatWinBarIcon#",
        current_mode == "agent" and " " or " ",
        "%#CopilotChatWinBarTitle#",
        mode_title(current_mode),
        "%#CopilotChatWinBarMeta#  ",
        layout_label(current_layout),
        "  %=%#CopilotChatWinBarMeta#switch <leader>cl ",
      })
    end

    local function apply_chat_window_style(window)
      if not window or not vim.api.nvim_win_is_valid(window) then
        return
      end

      local is_float = current_layout == "float"
      local winhighlight = table.concat({
        "Normal:CopilotChatNormal",
        "NormalNC:CopilotChatNormal",
        "NormalFloat:CopilotChatNormal",
        "FloatBorder:CopilotChatBorder",
        "FloatTitle:CopilotChatTitle",
        "FloatFooter:CopilotChatFooter",
        "CursorLine:CopilotChatCursorLine",
        "FoldColumn:CopilotChatNormal",
        "SignColumn:CopilotChatNormal",
        "EndOfBuffer:CopilotChatMuted",
        "WinSeparator:CopilotChatBorder",
        "WinBar:CopilotChatWinBar",
        "WinBarNC:CopilotChatWinBar",
      }, ",")

      vim.wo[window].number = false
      vim.wo[window].relativenumber = false
      vim.wo[window].signcolumn = "no"
      vim.wo[window].statuscolumn = ""
      vim.wo[window].wrap = true
      vim.wo[window].linebreak = true
      vim.wo[window].conceallevel = 0
      vim.wo[window].cursorline = true
      vim.wo[window].colorcolumn = ""
      vim.wo[window].winfixwidth = not is_float
      vim.wo[window].winhighlight = winhighlight
      vim.wo[window].winbar = is_float and "" or build_winbar()
      vim.wo[window].fillchars = is_float
          and "eob: ,fold: ,foldopen:,foldclose:,foldsep: "
        or "eob: ,fold: ,foldopen:,foldclose:,foldsep: ,vert:│"
    end

    local function refresh_chat_window()
      local chat_window = chat.chat and chat.chat.winnr or nil
      if chat_window and vim.api.nvim_win_is_valid(chat_window) then
        apply_chat_window_style(chat_window)
      end
    end

    local copilot_chat_group = vim.api.nvim_create_augroup("CopilotChatBufferLocal", { clear = true })
    vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "WinEnter" }, {
      group = copilot_chat_group,
      pattern = "*",
      callback = function(args)
        if vim.bo[args.buf].filetype ~= "copilot-chat" then
          return
        end

        vim.schedule(function()
          local window = vim.api.nvim_get_current_win()
          if vim.api.nvim_win_is_valid(window) and vim.api.nvim_win_get_buf(window) == args.buf then
            apply_chat_window_style(window)
          end
        end)
      end,
    })

    local function reconfigure_chat(open_after)
      chat.setup(mode_config(current_mode))
      if open_after then
        chat.open(mode_config(current_mode))
        refresh_chat_window()
      end
    end

    local function set_layout(layout_name, open_after)
      local normalized_layout = normalize_layout(layout_name)
      if not normalized_layout then
        vim.notify("CopilotChat layout must be 'side' or 'float'", vim.log.levels.WARN)
        return
      end

      local was_visible = chat.chat and chat.chat:visible() or false
      current_layout = normalized_layout
      vim.g.copilot_chat_layout = normalized_layout

      reconfigure_chat(open_after or was_visible)

      vim.notify("Copilot Chat layout: " .. layout_label(normalized_layout), vim.log.levels.INFO, {
        title = "Copilot Chat",
      })
    end

    local function open_in_layout(layout_name, input)
      set_layout(layout_name, false)

      if input and vim.trim(input) ~= "" then
        chat.ask(input, mode_config(current_mode))
        return
      end

      chat.open(mode_config(current_mode))
      refresh_chat_window()
    end

    local function pick_layout()
      local choices = {
        { id = "side", label = "Side Panel", description = "Docked split on the right" },
        { id = "float", label = "Floating Window", description = "Centered chat overlay" },
      }

      vim.ui.select(choices, {
        prompt = "Copilot layout> ",
        format_item = function(item)
          local suffix = item.id == current_layout and " (current)" or ""
          return string.format("%s%s - %s", item.label, suffix, item.description)
        end,
      }, function(choice)
        if choice then
          set_layout(choice.id, false)
        end
      end)
    end

    local function set_mode(mode_name)
      current_mode = mode_name
      reconfigure_chat(false)
    end

    local function open_mode(mode_name, input)
      set_mode(mode_name)

      if input and vim.trim(input) ~= "" then
        chat.ask(input, mode_config(mode_name))
        return
      end

      chat.open(mode_config(mode_name))
      refresh_chat_window()
    end

    vim.api.nvim_create_user_command("CopilotChatLayout", function(args)
      local layout_name = vim.trim(args.args or "")

      if layout_name == "" then
        pick_layout()
        return
      end

      set_layout(layout_name, false)
    end, {
      nargs = "?",
      force = true,
      complete = function()
        return { "side", "float" }
      end,
      desc = "Pick Copilot Chat layout",
    })

    vim.api.nvim_create_user_command("CopilotChatSide", function(args)
      open_in_layout("side", args.args)
    end, {
      nargs = "*",
      force = true,
      desc = "Open Copilot Chat in side panel",
    })

    vim.api.nvim_create_user_command("CopilotChatFloat", function(args)
      open_in_layout("float", args.args)
    end, {
      nargs = "*",
      force = true,
      desc = "Open Copilot Chat in floating window",
    })

    vim.api.nvim_create_user_command("CopilotChatChat", function(args)
      open_mode("chat", args.args)
    end, {
      nargs = "*",
      force = true,
      desc = "Copilot Chat standard mode",
    })

    vim.api.nvim_create_user_command("CopilotChatAgent", function(args)
      open_mode("agent", args.args)
    end, {
      nargs = "*",
      force = true,
      desc = "Copilot Chat agent mode",
    })

    reconfigure_chat(false)
  end,
}
