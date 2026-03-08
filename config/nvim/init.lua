require("config.lazy")
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- Enable 24-bit color
vim.opt.termguicolors = true
vim.opt.number = true

-- Preserve view when switching buffers
vim.opt.jumpoptions = "view"
