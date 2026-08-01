-- Debugging (DAP).
--
-- Entirely lazy: nothing here loads until you hit a <leader>D mapping, so the
-- debugger costs nothing on a normal editing session. Adapters are resolved
-- from Mason at load time and simply skipped when absent, which keeps the
-- config working on a machine where you have not installed them.
--
-- Install adapters with `:Mason` — e.g. `java-debug-adapter`, `codelldb`,
-- `delve`, `debugpy`, `js-debug-adapter`.

local mason_bin = require("core.utils").tool_path

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- required by dap-ui
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<leader>D", "", desc = "Debug" },
      {
        "<leader>Db",
        function() require("dap").toggle_breakpoint() end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>DB",
        function()
          vim.ui.input({ prompt = "Breakpoint condition: " }, function(input)
            if input and input ~= "" then
              require("dap").set_breakpoint(input)
            end
          end)
        end,
        desc = "Conditional breakpoint",
      },
      { "<leader>Dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>Di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>Do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>DO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>Dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>Dl", function() require("dap").run_last() end, desc = "Run last configuration" },
      { "<leader>Dt", function() require("dap").terminate() end, desc = "Terminate session" },
      {
        "<leader>Du",
        function() require("dapui").toggle() end,
        desc = "Toggle debugger UI",
      },
      {
        "<leader>De",
        function() require("dapui").eval(nil, { enter = true }) end,
        mode = { "n", "v" },
        desc = "Evaluate expression",
      },
    },
    config = function()
      local dap = require("dap")
      local ui = require("core.ui")
      local icons = require("core.icons")

      -- Breakpoint signs follow the palette like everything else.
      local function apply_dap_highlights()
        local p = ui.palette()
        local hl = vim.api.nvim_set_hl

        hl(0, "DapBreakpoint", { fg = p.red })
        hl(0, "DapBreakpointCondition", { fg = p.yellow })
        hl(0, "DapBreakpointRejected", { fg = p.muted })
        hl(0, "DapLogPoint", { fg = p.cyan })
        hl(0, "DapStopped", { fg = p.green })
        hl(0, "DapStoppedLine", { bg = ui.blend(p.green, p.bg, 0.15) })
      end

      apply_dap_highlights()
      ui.on_theme_change(ui.create_augroup("DapHighlights"), apply_dap_highlights)

      vim.fn.sign_define("DapBreakpoint", {
        text = icons.dap.breakpoint,
        texthl = "DapBreakpoint",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointCondition", {
        text = icons.dap.breakpoint_conditional,
        texthl = "DapBreakpointCondition",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointRejected", {
        text = icons.dap.breakpoint_rejected,
        texthl = "DapBreakpointRejected",
        numhl = "",
      })
      vim.fn.sign_define("DapLogPoint", {
        text = icons.dap.log_point,
        texthl = "DapLogPoint",
        numhl = "",
      })
      vim.fn.sign_define("DapStopped", {
        text = icons.dap.stopped,
        texthl = "DapStopped",
        linehl = "DapStoppedLine",
        numhl = "DapStopped",
      })

      -- Adapters ---------------------------------------------------------
      local codelldb = mason_bin("codelldb")
      if codelldb then
        dap.adapters.codelldb = {
          type = "server",
          port = "${port}",
          executable = { command = codelldb, args = { "--port", "${port}" } },
        }

        local lldb_config = {
          {
            name = "Launch executable",
            type = "codelldb",
            request = "launch",
            program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
          },
        }

        dap.configurations.rust = lldb_config
        dap.configurations.c = lldb_config
        dap.configurations.cpp = lldb_config
      end

      local delve = mason_bin("dlv")
      if delve then
        dap.adapters.go = {
          type = "server",
          port = "${port}",
          executable = { command = delve, args = { "dap", "-l", "127.0.0.1:${port}" } },
        }
        dap.configurations.go = {
          { type = "go", name = "Debug package", request = "launch", program = "${fileDirname}" },
          { type = "go", name = "Debug test", request = "launch", mode = "test", program = "${fileDirname}" },
        }
      end

      local debugpy = mason_bin("debugpy-adapter")
      if debugpy then
        dap.adapters.python = { type = "executable", command = debugpy }
        dap.configurations.python = {
          {
            type = "python",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
        }
      end

      -- UI ---------------------------------------------------------------
      local dapui = require("dapui")

      dapui.setup({
        icons = { expanded = icons.ui.chevron_down, collapsed = icons.ui.chevron_right },
        floating = { border = "rounded" },
        layouts = {
          {
            position = "left",
            size = 40,
            elements = {
              { id = "scopes", size = 0.4 },
              { id = "breakpoints", size = 0.2 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.15 },
            },
          },
          {
            position = "bottom",
            size = 10,
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
          },
        },
      })

      -- Open the UI with the session and close it when the session ends, so
      -- the debugger never leaves panels behind in a normal editing layout.
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open({}) end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close({}) end
      dap.listeners.before.event_exited["dapui"] = function() dapui.close({}) end

      require("nvim-dap-virtual-text").setup({
        commented = true, -- render inline values as comments
        virt_text_pos = "eol",
      })
    end,
  },
}
