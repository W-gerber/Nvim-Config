return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
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
        local opts = { buffer = ev.buf, silent = true }
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
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
        map("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "LSP: Format")

        -- Diagnostics
        map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
        map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
        map("n", "<leader>d", vim.diagnostic.open_float, "Diagnostic: float")
      end,
    })

    -- Java (jdtls)
    -- Prefer Mason's installed wrapper when available.
    local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"
    if vim.fn.has("win32") == 1 then
      mason_bin = mason_bin .. ".cmd"
    end
    local cmd = vim.fn.filereadable(mason_bin) == 1 and mason_bin or vim.fn.exepath("jdtls")

    -- Register config for Neovim's built-in LSP manager.
    -- Use the public API (vim.lsp.config) when available, fallback for older Neovim.
    local lsp_cfg = {
      cmd = { cmd },
      filetypes = { "java" },
      root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle" },
      capabilities = capabilities,
    }

    if vim.lsp.config and type(vim.lsp.config) == "function" then
      vim.lsp.config("jdtls", lsp_cfg)
    elseif vim.lsp.config and vim.lsp.config._configs then
      vim.lsp.config._configs.jdtls = lsp_cfg
    end

    -- Enable jdtls for java buffers.
    -- If jdtls isn't installed yet, Mason will install it on start; opening a Java file after that will attach.
    vim.lsp.enable("jdtls")

    -- Lua (lua_ls) — for editing this Neovim config
    local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
    if ok_lspconfig and lspconfig.lua_ls then
      lspconfig.lua_ls.setup({
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
      })
    end
  end,
}
