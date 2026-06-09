return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local function register_server(name, config)
      if vim.lsp.config and type(vim.lsp.config) == "function" then
        vim.lsp.config(name, config)
        return true
      end

      if vim.lsp.config and vim.lsp.config._configs then
        vim.lsp.config._configs[name] = config
        return true
      end

      return false
    end

    local function resolve_executable(name)
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/" .. name
      if vim.fn.has("win32") == 1 then
        mason_bin = mason_bin .. ".cmd"
      end

      if vim.fn.filereadable(mason_bin) == 1 then
        return mason_bin
      end

      local system_bin = vim.fn.exepath(name)
      if system_bin ~= "" then
        return system_bin
      end

      return nil
    end

    local function format_java_with_google_java_format(bufnr)
      local formatter = resolve_executable("google-java-format")
      if not formatter then
        return false, "google-java-format is not installed yet"
      end

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local input = table.concat(lines, "\n")
      if #lines > 0 then
        input = input .. "\n"
      end

      local output = vim.fn.system({ formatter, "-" }, input)
      if vim.v.shell_error ~= 0 then
        return false, tostring(output):gsub("%s+$", "")
      end

      local formatted = vim.split(output, "\n", { plain = true, trimempty = false })
      if formatted[#formatted] == "" then
        table.remove(formatted, #formatted)
      end

      local view = vim.fn.winsaveview()
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
      vim.fn.winrestview(view)
      return true
    end

    local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    if ok_cmp then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    -- Floating info windows (hover/signature/diagnostics)
    vim.diagnostic.config({
      float = { border = "rounded" },
      virtual_text = { spacing = 4, prefix = "●" },
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN]  = " ",
          [vim.diagnostic.severity.HINT]  = "󰌵 ",
          [vim.diagnostic.severity.INFO]  = " ",
        },
      },
    })

    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = "rounded",
    })

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
      border = "rounded",
    })

    local lsp_group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", {
      group = lsp_group,
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        -- For Java (jdtls), disable semantic tokens so Treesitter controls
        -- highlighting. This avoids multi-colored chains like System.out.print.
        if client and client.name == "jdtls" and client.server_capabilities.semanticTokensProvider then
          client.server_capabilities.semanticTokensProvider = nil
        end

        local opts = { buffer = ev.buf, silent = true }
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
        end
        local function format_buffer()
          local supports_formatting = false
          local is_java_buffer = vim.bo[ev.buf].filetype == "java"

          for _, attached_client in ipairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
            if attached_client.supports_method and attached_client:supports_method("textDocument/formatting") then
              supports_formatting = true
              break
            end
          end

          if not supports_formatting then
            if is_java_buffer then
              local ok_java, err = format_java_with_google_java_format(ev.buf)
              if ok_java then
                vim.notify("Formatted with google-java-format", vim.log.levels.INFO)
              else
                vim.notify("Java format failed: " .. tostring(err), vim.log.levels.WARN)
              end
              return
            end

            vim.notify("No formatter attached for this buffer", vim.log.levels.INFO)
            return
          end

          local ok_format, err = pcall(vim.lsp.buf.format, { async = true, bufnr = ev.buf })
          if not ok_format then
            if is_java_buffer then
              local ok_java, java_err = format_java_with_google_java_format(ev.buf)
              if ok_java then
                vim.notify("Formatted with google-java-format", vim.log.levels.INFO)
                return
              end

              err = java_err or err
            end

            vim.notify("Format failed: " .. tostring(err), vim.log.levels.WARN)
          end
        end

        -- Navigation
        map("n", "gd", vim.lsp.buf.definition, "LSP: Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to declaration")
        map("n", "gi", vim.lsp.buf.implementation, "LSP: Go to implementation")
        map("n", "gr", vim.lsp.buf.references, "LSP: References")
        map("n", "gt", vim.lsp.buf.type_definition, "LSP: Type definition")

        -- Info
        map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
        map("n", "gK", vim.lsp.buf.signature_help, "LSP: Signature")
        map("i", "<C-k>", vim.lsp.buf.signature_help, "LSP: Signature (insert)")

        -- Actions
        map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: Code action")
        map("n", "<leader>cf", format_buffer, "LSP: Format")

        -- Diagnostics
        map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        map("n", "<leader>d", vim.diagnostic.open_float, "Diagnostic: float")
      end,
    })

    -- Java (jdtls)
    -- Prefer Mason's installed wrapper when available.
    local cmd = resolve_executable("jdtls") or ""

    if cmd ~= "" then
      -- Register config for Neovim's built-in LSP manager.
      -- Use the public API (vim.lsp.config) when available, fallback for older Neovim.
      local lsp_cfg = {
        cmd = { cmd },
        filetypes = { "java" },
        root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle" },
        capabilities = capabilities,
      }

      if register_server("jdtls", lsp_cfg) then
        -- Enable jdtls for java buffers.
        vim.lsp.enable("jdtls")
      end
    end

    -- Lua (lua_ls) — for editing this Neovim config
    local lua_ls = {
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = {
            checkThirdParty = false,
            library = { vim.env.VIMRUNTIME },
          },
          diagnostics = { globals = { "vim" } },
          telemetry = { enable = false },
        },
      },
    }

    if register_server("lua_ls", lua_ls) then
      vim.lsp.enable("lua_ls")
    else
      local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
      if ok_lspconfig and lspconfig.lua_ls then
        lspconfig.lua_ls.setup(lua_ls)
      end
    end
  end,
}
