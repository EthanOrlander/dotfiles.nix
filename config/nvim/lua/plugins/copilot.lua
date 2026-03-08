return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("codecompanion").setup({
      adapters = {
        http = {
          bedrock = function()
            return require("codecompanion.adapters.http").extend("anthropic", {
              env = {
                api_key = "cmd:aws bedrock-runtime invoke-model --profile BedrockAccess",
              },
              url = "https://bedrock-runtime.us-west-2.amazonaws.com/model/anthropic.claude-sonnet-4-5-20250929-v1:0/invoke",
              schema = {
                model = {
                  default = "anthropic.claude-sonnet-4-5-20250929-v1:0",
                },
              },
            })
          end,
        },
      },
      strategies = {
        chat = {
          adapter = "bedrock",
        },
        inline = {
          adapter = "bedrock",
        },
      },
    })

    -- Keymaps
    vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("v", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("v", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<leader>ct", "<cmd>CodeCompanionToggle<cr>", { noremap = true, silent = true })
  end,
}
