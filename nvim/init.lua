_G.dd = function(...)
	Snacks.debug.inspect(...)
end
_G.bt = function()
	Snacks.debug.backtrace()
end
vim.print = _G.dd
-- see: https://github.com/neovim/neovim/issues/31675
vim.hl = vim.highlight

require("config.lazy")
