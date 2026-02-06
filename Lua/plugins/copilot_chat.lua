return {
  "CopilotC-Nvim/CopilotChat.nvim",
  event = "VeryLazy",
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
    "CopilotChatAgent",
    "CopilotChatExplain",
    "CopilotChatReview",
    "CopilotChatFix",
    "CopilotChatOptimize",
  },
  keys = {
    { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "Copilot Chat: toggle", mode = "n" },
    { "<leader>cp", "<cmd>CopilotChatPrompts<cr>", desc = "Copilot Chat: prompts", mode = "n" },
    { "<leader>cm", "<cmd>CopilotChatModels<cr>", desc = "Copilot Chat: models", mode = "n" },
    { "<leader>cA", "<cmd>CopilotChatAgent<cr>", desc = "Copilot Chat: agent mode", mode = "n" },
    {
      "<leader>ca",
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

    -- Keep styling consistent with the active colorscheme (no hard-coded colors)
    local function hl_link(name, target)
      pcall(vim.api.nvim_set_hl, 0, name, { link = target, default = true })
    end

    hl_link("CopilotChatHeader", "Title")
    hl_link("CopilotChatSeparator", "Comment")
    hl_link("CopilotChatSelection", "Visual")
    hl_link("CopilotChatStatus", "DiagnosticInfo")
    hl_link("CopilotChatHelp", "Comment")
    hl_link("CopilotChatResource", "Type")
    hl_link("CopilotChatTool", "DiagnosticHint")
    hl_link("CopilotChatPrompt", "Special")
    hl_link("CopilotChatModel", "Identifier")
    hl_link("CopilotChatUri", "Underlined")
    hl_link("CopilotChatAnnotation", "Comment")

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-*",
      callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.conceallevel = 0
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
      end,
    })

    chat.setup({
      window = {
        layout = "vertical",
        width = 0.42,
        border = "rounded",
        title = " Copilot Chat ",
        zindex = 100,
      },
      headers = {
        user = " You",
        assistant = " Copilot",
        tool = " Tool",
      },
      separator = "─",
      auto_fold = true,
      auto_insert_mode = true,
      prompts = {
        Agent = {
          system_prompt = table.concat({
            "You are an agentic coding assistant inside Neovim.",
            "Prefer making concrete, reviewable changes (diffs) over vague advice.",
            "When needed, request context using resources like #file, #buffer:active, #gitdiff:staged, #glob, #grep.",
            "If you propose edits, format them as a unified diff so they can be applied.",
          }, "\n"),
          description = "Agent-like mode (diff-first)",
        },
      },
    })
  end,
}
