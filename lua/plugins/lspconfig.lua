return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    -- ------------------------------------------------------------------
    -- Capabilities
    -- ------------------------------------------------------------------
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok_cmp then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    -- Ask servers for the extras we actually render: snippet bodies in
    -- completion, and folding ranges for servers that compute them better than
    -- Treesitter can.
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }

    -- Diagnostic appearance (icons, virtual text, floats, highlights) is owned
    -- by core.diagnostics and configured during startup — nvim-lint publishes
    -- into the same namespace, so it cannot depend on this plugin loading.

    -- ------------------------------------------------------------------
    -- Buffer-local keymaps and per-server tweaks
    -- ------------------------------------------------------------------
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
          return
        end

        local buf = event.buf

        -- jdtls' semantic tokens fight Treesitter and produce multi-colored
        -- chains like `System.out.print`; let Treesitter own Java highlighting.
        if client.name == "jdtls" and client.server_capabilities.semanticTokensProvider then
          client.server_capabilities.semanticTokensProvider = nil
        end

        -- Highlight other references to the symbol under the cursor. The
        -- autocommands are buffer-scoped to their own group so detaching one
        -- client doesn't tear down highlighting for the others.
        if client:supports_method("textDocument/documentHighlight") then
          local group = vim.api.nvim_create_augroup("UserLspHighlight" .. buf, { clear = true })

          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            group = group,
            buffer = buf,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = group,
            buffer = buf,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd("LspDetach", {
            group = group,
            buffer = buf,
            callback = function()
              vim.lsp.buf.clear_references()
              pcall(vim.api.nvim_del_augroup_by_name, "UserLspHighlight" .. buf)
            end,
          })
        end

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
        end

        -- Inlay hints, when the server offers them. On by default: seeing
        -- inferred types is most of the value of having a type-aware server.
        if client:supports_method("textDocument/inlayHint") then
          vim.lsp.inlay_hint.enable(true, { bufnr = buf })

          map("n", "<leader>ch", function()
            local enabled = not vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
            vim.lsp.inlay_hint.enable(enabled, { bufnr = buf })
            vim.notify("Inlay hints " .. (enabled and "on" or "off"), vim.log.levels.INFO)
          end, "LSP: Toggle inlay hints")
        end

        -- Navigation. Telescope gives a searchable, previewable list where the
        -- built-ins would dump straight into the quickfix window.
        local function picker(name, fallback)
          return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok and builtin[name] then
              builtin[name]({ reuse_win = true })
            else
              fallback()
            end
          end
        end

        map("n", "gd", picker("lsp_definitions", vim.lsp.buf.definition), "LSP: Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to declaration")
        map("n", "gi", picker("lsp_implementations", vim.lsp.buf.implementation), "LSP: Go to implementation")
        map("n", "gr", picker("lsp_references", vim.lsp.buf.references), "LSP: References")
        map("n", "gt", picker("lsp_type_definitions", vim.lsp.buf.type_definition), "LSP: Type definition")

        -- Info (border is passed per call; vim.lsp.with is deprecated on 0.11+)
        map("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "LSP: Hover")
        map("n", "gK", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "LSP: Signature")
        map("i", "<C-k>", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "LSP: Signature")

        -- Actions (formatting lives in conform.nvim, see plugins/conform.lua)
        map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: Code action")

        -- Diagnostics
        map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        map(
          "n",
          "[e",
          function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end,
          "Previous error"
        )
        map(
          "n",
          "]e",
          function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end,
          "Next error"
        )
        map("n", "<leader>d", vim.diagnostic.open_float, "Diagnostic: line float")
      end,
    })

    -- ------------------------------------------------------------------
    -- Servers
    -- ------------------------------------------------------------------
    -- Shared defaults for every server, including the ones mason-lspconfig
    -- enables automatically once they are installed.
    vim.lsp.config("*", { capabilities = capabilities })

    -- Java. Mason's wrapper is preferred; skip registration when it is missing
    -- so `vim.lsp.enable` doesn't spawn a nonexistent command on every buffer.
    local jdtls = require("core.utils").tool_path("jdtls")
    if jdtls then
      vim.lsp.config("jdtls", {
        cmd = { jdtls },
        filetypes = { "java" },
        root_markers = { "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle", ".git" },
      })
      vim.lsp.enable("jdtls")
    end

    -- Lua, for editing this config (lazydev.nvim supplies the library paths).
    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = { checkThirdParty = false },
          diagnostics = { globals = { "vim" } },
          hint = { enable = true, arrayIndex = "Disable" },
          format = { enable = false }, -- stylua owns formatting, via conform
          telemetry = { enable = false },
        },
      },
    })
    vim.lsp.enable("lua_ls")

    -- Settings for servers this config does not install but is ready for.
    -- `vim.lsp.config` only records a configuration — nothing starts until the
    -- server exists, at which point mason-lspconfig's `automatic_enable` turns
    -- it on with these settings already in place. Install any of them with
    -- `:Mason`; no further wiring is needed.
    local optional_servers = {
      ts_ls = {
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "literals",
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayVariableTypeHints = false,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "literals",
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
        },
      },

      gopls = {
        settings = {
          gopls = {
            analyses = { unusedparams = true, shadow = true },
            staticcheck = true,
            gofumpt = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              constantValues = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      },

      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            inlayHints = {
              parameterHints = { enable = true },
              typeHints = { enable = true },
            },
          },
        },
      },

      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",
              autoImportCompletions = true,
              inlayHints = { variableTypes = true, functionReturnTypes = true },
            },
          },
        },
      },

      omnisharp = {
        settings = {
          FormattingOptions = { EnableEditorConfigSupport = true },
          RoslynExtensionsOptions = { EnableAnalyzersSupport = true },
        },
      },

      jsonls = {
        settings = {
          json = { validate = { enable = true } },
        },
      },

      yamlls = {
        settings = {
          yaml = { keyOrdering = false }, -- alphabetical key warnings are noise
        },
      },

      -- Web trio + Tailwind. Defaults are good; they are listed so the set of
      -- languages this config claims to support is visible in one place.
      html = {},
      cssls = {},
      tailwindcss = {},
      taplo = {},
      bashls = {},
    }

    for server, config in pairs(optional_servers) do
      vim.lsp.config(server, config)
    end
  end,
}
