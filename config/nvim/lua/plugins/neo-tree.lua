return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, recommended for file icons
      "MunifTanjim/nui.nvim",
      -- Uncomment below to enable image support in preview window
      -- { "3rd/image.nvim", opts = {} },
    },
    lazy = false, -- disables lazy loading for this plugin
    opts = {
      -- Example config options:
      window = {
        position = "left",
        width = 30,
      },
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
      },
      -- Add more options as desired from :help neo-tree-config
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)
    end,
  },
}
