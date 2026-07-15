local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local ok, lock = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
  end)
  local commit = ok and lock["lazy.nvim"] and lock["lazy.nvim"].commit
  if not commit or not commit:match("^[0-9a-fA-F]+$") or (#commit ~= 40 and #commit ~= 64) then
    vim.api.nvim_echo({
      { "Refusing to bootstrap lazy.nvim without a pinned commit in " .. lockfile, "ErrorMsg" },
    }, true, {})
    os.exit(1)
  end

  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--no-checkout", lazyrepo, lazypath })
  if vim.v.shell_error == 0 then
    out = vim.fn.system({ "git", "-C", lazypath, "checkout", "--detach", commit })
  end
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(lazypath, "rf")
    vim.api.nvim_echo({
      { "Failed to install pinned lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit...", "" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = {
    missing = false,
    colorscheme = { "gruvbox" },
  },
  -- automatically check for plugin updates
  checker = {
    enabled = true,
    frequency = 3600 * 24 * 7,
  },
})

require("config.lazy_quarantine").setup()

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.test_runner").setup()
