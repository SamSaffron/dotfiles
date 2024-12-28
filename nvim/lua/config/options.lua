-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.guifont = "Consolas 14"
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.expandtab = true
vim.opt.history = 1000
vim.opt.wrap = true

vim.opt.directory = vim.fn.expand("$HOME/.vim/swapfiles//")
vim.opt.backupdir = vim.fn.expand("$HOME/.vim/backupdir//")
vim.g.autoformat = true
vim.g.snacks_animate = false
