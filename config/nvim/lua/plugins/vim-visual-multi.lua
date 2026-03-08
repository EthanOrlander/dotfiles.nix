return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "VeryLazy",
    init = function()
      -- Default key mappings are enabled by default
      -- https://github.com/mg979/vim-visual-multi/wiki/Mappings

      -- Some useful customizations (optional)
      vim.g.VM_maps = {
        -- Select cursor down/up
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        
        -- Add cursor down/up (alternative to using mouse)
        ["Add Cursor Down"] = "<C-j>",
        ["Add Cursor Up"] = "<C-k>",
        
        -- Skip current and search for next pattern matches
        ["Skip Region"] = "<C-s>",
        ["Remove Region"] = "<C-x>", -- Changed from <C-p> to avoid Telescope conflict
      }
      
      -- Set default colors
      vim.g.VM_theme = "nord"
      
      -- Enable all mode mappings (visual, insert, etc)
      vim.g.VM_default_mappings = 1
    end,
  },
}