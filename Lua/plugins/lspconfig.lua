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
    })

    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = "rounded",
    })

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
      border = "rounded",
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }
        vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP: Hover" }))
        vim.keymap.set("n", "gK", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "LSP: Signature" }))
      end,
    })

    -- Java (jdtls)
    -- Prefer Mason's installed wrapper when available.
    local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"
    if vim.fn.has("win32") == 1 then
      mason_bin = mason_bin .. ".cmd"
    end
    local cmd = vim.fn.filereadable(mason_bin) == 1 and mason_bin or vim.fn.exepath("jdtls")

    -- Register config for Neovim 0.11's built-in LSP manager.
    vim.lsp.config._configs.jdtls = {
      cmd = { cmd },
      filetypes = { "java" },
      root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle" },
      capabilities = capabilities,
    }

    -- Enable jdtls for java buffers.
    -- If jdtls isn't installed yet, Mason will install it on start; opening a Java file after that will attach.
    vim.lsp.enable("jdtls")
  end,
}
