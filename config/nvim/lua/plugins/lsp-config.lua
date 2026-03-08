return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        PATH = "prepend",
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "yamlls", "pyright", "gopls" },
        -- Note: sorbet is not included here because it needs to be installed
        -- via your Ruby project's Gemfile (gem 'sorbet'), not via Mason
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      -- 1) diagnostic symbols
      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      -- Modern way to set diagnostic signs - no need for sign_define

      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 2 },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = signs.Error,
            [vim.diagnostic.severity.WARN] = signs.Warn,
            [vim.diagnostic.severity.INFO] = signs.Info,
            [vim.diagnostic.severity.HINT] = signs.Hint,
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- 2) shared on_attach + capabilities (for completion plugins)
      local on_attach = function(client, bufnr)
        local bufmap = function(mode, lhs, rhs)
          vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, {
            noremap = true,
            silent = true,
          })
        end
        bufmap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
        bufmap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
        bufmap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>")
        bufmap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
        bufmap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>")
        bufmap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>")
        -- Auto-format on save
        if client.server_capabilities.documentFormattingProvider then
          local format_augroup = vim.api.nvim_create_augroup("LspFormat" .. bufnr, { clear = true })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = format_augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end
      end

      -- If you have nvim-cmp installed, hook in its capabilities:
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if has_cmp then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      -- 3) server configurations
      -- Lua
      lspconfig.lua_ls.setup {
        on_attach = on_attach,
        capabilities = capabilities,
      }

      -- TypeScript / JavaScript
      lspconfig.ts_ls.setup {
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          -- Organize and add missing imports on save
          local ts_organize_group = vim.api.nvim_create_augroup("TsOrganizeImports" .. bufnr, { clear = true })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = ts_organize_group,
            buffer = bufnr,
            callback = function()
              -- First add missing imports
              vim.lsp.buf.code_action({
                context = { only = { "source.addMissingImports.ts" }, diagnostics = {} },
                apply = true,
              })
              -- Then organize/remove unused imports
              vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" }, diagnostics = {} },
                apply = true,
              })
            end,
          })
        end,
        capabilities = capabilities,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayFunctionParameterTypeHints = true,
            },
            suggest = {
              autoImports = true,
            },
          },
          javascript = {
            suggest = {
              autoImports = true,
            },
          },
        },
      }

      -- Go
      lspconfig.gopls.setup {
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          -- Setting up autocommands for golang
          local go_imports_group = vim.api.nvim_create_augroup("GoImports", { clear = true })
          -- Run goimports after file save (BufWritePost event so it doesn't warn about changes)
          vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = "*.go",
            callback = function()
              -- Get the current file path
              local filepath = vim.fn.expand("%:p")
              -- Run goimports on the file
              local output = vim.fn.system("goimports -w " .. filepath)
              if vim.v.shell_error ~= 0 then
                -- Show error message if goimports failed
                vim.notify("goimports failed: " .. output, vim.log.levels.ERROR)
              else
                -- Reload the buffer without prompting to avoid "file changed" warning
                vim.cmd("silent! edit!")
              end
            end,
            group = go_imports_group,
          })

          -- Regular LSP import organization on pre-save as a backup
          vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*.go",
            callback = function()
              -- Use LSP only if the goimports-hook isn't sufficient
              vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
            end,
            group = go_imports_group,
          })
        end,
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
            gofumpt = true,
            -- Enable import organization
            importShortcut = "Both",
            usePlaceholders = true,
            completeUnimported = true,
          },
        },
      }

      -- Python
      lspconfig.pyright.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
              typeCheckingMode = "basic",
            },
          },
        },
      }

      -- YAML
      lspconfig.yamlls.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          yaml = {
            schemas = {
              ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
              ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.yml",
            },
            schemaStore = {
              enable = true,
              url = "https://www.schemastore.org/api/json/catalog.json",
            },
            validate = true,
            format = { enabled = true },
          },
        },
      }

      -- Ruby (Sorbet)
      -- Sorbet needs to be installed in your project via Gemfile
      lspconfig.sorbet.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
        root_dir = lspconfig.util.root_pattern("sorbet/config", "Gemfile"),
      }
    end,
  },
}
