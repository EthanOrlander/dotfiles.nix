return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvimtools/none-ls-extras.nvim",
  },
  config = function()
    local null_ls = require("null-ls")
    local h = require("null-ls.helpers")

    -- Use builtin rubocop with custom wrapper command
    local rubocop_formatting = null_ls.builtins.formatting.rubocop.with({
      command = os.getenv("HOME") .. "/.local/bin/rubocop-format",
      timeout = 30000, -- 30 seconds timeout for direnv loading
    })

    -- Use builtin rubocop diagnostics with stderr suppressed
    -- We need to suppress stderr to hide rubocop config warnings
    local rubocop_diagnostics = null_ls.builtins.diagnostics.rubocop.with({
      command = "sh",
      args = { "-c", "bundle exec rubocop -f json --force-exclusion --stdin $FILENAME 2>/dev/null" },
      to_stdin = true,
      timeout = 30000,
    })

    -- Old custom diagnostics approach (disabled)
    -- local rubocop_diagnostics = h.make_builtin({
    --   name = "rubocop",
    --   meta = {
    --     url = "https://github.com/rubocop/rubocop",
    --     description = "Ruby linter",
    --   },
    --   method = null_ls.methods.DIAGNOSTICS,
    --   filetypes = { "ruby" },
    --   generator_opts = {
    --     command = rubocop_cmd,
    --     args = { "-f", "json", "--force-exclusion", "--stdin", "$FILENAME" },
    --     to_stdin = true,
    --     format = "json",
    --     check_exit_code = function(code)
    --       return code <= 1
    --     end,
    --     on_output = h.diagnostics.from_json({
    --       attributes = {
    --         severity = "severity",
    --       },
    --       severities = {
    --         convention = h.diagnostics.severities.information,
    --         warning = h.diagnostics.severities.warning,
    --         error = h.diagnostics.severities.error,
    --         fatal = h.diagnostics.severities.error,
    --       },
    --     }),
    --   },
    --   factory = h.generator_factory,
    -- }).with({
    --   condition = function()
    --     return true
    --   end,
    -- })

    null_ls.setup({
      default_timeout = 30000, -- 30 second timeout globally
      sources = {
        -- Prettier (JS, TS, JSX, TSX, CSS, HTML, JSON, YAML, Markdown, etc.)
        null_ls.builtins.formatting.prettier.with({
          filetypes = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "css",
            "scss",
            "html",
            "json",
            "yaml",
            "markdown",
            "graphql",
          },
        }),

        -- ESLint (diagnostics and code actions)
        -- Using none-ls-extras for ESLint support
        require("none-ls.diagnostics.eslint_d").with({
          condition = function(utils)
            return utils.root_has_file({
              "eslint.config.mjs",
              "eslint.config.js",
              ".eslintrc.js",
              ".eslintrc.json",
            })
          end,
        }),
        require("none-ls.code_actions.eslint_d").with({
          condition = function(utils)
            return utils.root_has_file({
              "eslint.config.mjs",
              "eslint.config.js",
              ".eslintrc.js",
              ".eslintrc.json",
            })
          end,
        }),

        -- Python formatters
        null_ls.builtins.formatting.black.with({
          extra_args = { "--line-length", "80" },
        }),
        null_ls.builtins.formatting.isort.with({
          extra_args = { "--profile", "black", "--line-length", "80" },
        }),

        -- Python linters - commented out, not installed
        -- null_ls.builtins.diagnostics.flake8,
        null_ls.builtins.diagnostics.mypy.with({
          extra_args = function()
            local config = vim.fn.findfile(".mypy.ini", ".;")
            if config ~= "" then
              return { "--config", config }
            end
            return {}
          end,
        }),
      },
      -- Format on save
      on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          local format_augroup = vim.api.nvim_create_augroup("NullLsFormat" .. bufnr, { clear = true })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = format_augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                bufnr = bufnr,
                timeout_ms = 30000, -- 30 second timeout for slow formatters (direnv)
                filter = function(formatting_client)
                  -- Use none-ls for formatting
                  return formatting_client.name == "null-ls"
                end,
              })
            end,
          })
        end
      end,
    })

    -- Register rubocop sources after setup
    null_ls.register(rubocop_formatting)
    null_ls.register(rubocop_diagnostics)
  end,
}
