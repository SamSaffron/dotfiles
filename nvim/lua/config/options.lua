local opt = vim.opt

-- General
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.swapfile = true
opt.dir = vim.fn.expand("$HOME/.vim/swapfiles//")
opt.backup = true
opt.backupdir = vim.fn.expand("$HOME/.vim/backupdir//")
opt.undofile = true
opt.history = 1000
opt.hidden = true

-- UI
opt.number = false
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.showmode = false
opt.showcmd = true
opt.cmdheight = 1
opt.guicursor = ""

-- Indenting
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.autoindent = true
opt.smartindent = true
opt.cindent = true

-- Search
opt.hlsearch = false
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Appearance
opt.guifont = "Consolas:h14"
opt.cursorline = true
