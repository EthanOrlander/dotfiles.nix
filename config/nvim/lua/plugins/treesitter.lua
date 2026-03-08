return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "lua", "vim", "bash", "javascript", "typescript", "tsx" },
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
