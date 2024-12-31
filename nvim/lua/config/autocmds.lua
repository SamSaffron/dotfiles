local api = vim.api

-- Create autogroup
local group = api.nvim_create_augroup("VimrcGroup", { clear = true })

api.nvim_create_autocmd({ "BufWinEnter" }, {
	group = group,
	pattern = "*",
	command = "match ExtraWhitespace /\\s\\+$/",
})

api.nvim_create_autocmd({ "InsertEnter" }, {
	group = group,
	pattern = "*",
	command = "match ExtraWhitespace /\\s\\+\\%#\\@<!$/",
})

api.nvim_create_autocmd({ "InsertLeave" }, {
	group = group,
	pattern = "*",
	command = "match ExtraWhitespace /\\s\\+$/",
})

api.nvim_create_autocmd({ "BufWinLeave" }, {
	group = group,
	pattern = "*",
	callback = function()
		vim.fn.clearmatches()
	end,
})

-- Search highlighting behavior
api.nvim_create_autocmd({ "CmdlineLeave" }, {
	group = group,
	pattern = "[/\\?]",
	command = "set nohlsearch",
})

api.nvim_create_autocmd({ "CmdlineEnter" }, {
	group = group,
	pattern = "[/,\\?]",
	command = "set hlsearch",
})

-- File type specific settings
api.nvim_create_autocmd({ "FileType" }, {
	group = group,
	pattern = { "c", "cpp" },
	callback = function()
		-- MRI Indent settings
		vim.bo.cindent = true
		vim.bo.expandtab = false
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
		vim.bo.tabstop = 8
		vim.bo.textwidth = 80
		vim.opt_local.cinoptions = "(0,t0"
	end,
})

api.nvim_create_autocmd({ "FileType" }, {
	group = group,
	pattern = "puppet",
	callback = function()
		-- Puppet indent settings
		vim.bo.expandtab = false
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
		vim.bo.tabstop = 4
		vim.bo.textwidth = 80
	end,
})

-- Filetype detection
api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = group,
	pattern = "Guardfile",
	command = "set filetype=ruby",
})

api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = group,
	pattern = "*.pill",
	command = "set filetype=ruby",
})

api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = group,
	pattern = "*.es6",
	command = "set filetype=javascript",
})

api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = group,
	pattern = "*.es6.erb",
	command = "set filetype=javascript",
})

api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = group,
	pattern = "*.pp",
	command = "set filetype=puppet",
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client then
			-- very annoying highlighting of current word
			client.server_capabilities.documentHighlightProvider = false
		end
	end,
})
