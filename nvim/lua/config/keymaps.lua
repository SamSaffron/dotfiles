local map = vim.keymap.set

-- General mappings
map("n", "<F12>", ":set number!<CR>", { silent = true })
map("n", "<C-TAB>", ":tabnext<CR>", { silent = true })
map("n", "<C-S-TAB>", ":tabprevious<CR>", { silent = true })
map("n", "<F9>", ":previous<CR>", { silent = true })
map("n", "<F10>", ":next<CR>", { silent = true })

-- Leader mappings
map("n", "<leader>s", ":!touch tmp/refresh_browser<CR><CR>", { silent = true })
map("n", "<leader>g", ":Git gui<CR><CR>", { silent = true })
map("n", "<leader>m", "<Plug>(git-messenger)", { silent = true })
map("n", "<leader>l", function()
	if vim.o.hlsearch and vim.v.hlsearch == 1 then
		return ":nohls<CR>"
	else
		return ":set hls<CR>"
	end
end, { expr = true, silent = true })

-- Window navigation (Alt + Arrow keys)
map("n", "<A-Up>", ":wincmd k<CR>", { silent = true })
map("n", "<A-Down>", ":wincmd j<CR>", { silent = true })
map("n", "<A-Left>", ":wincmd h<CR>", { silent = true })
map("n", "<A-Right>", ":wincmd l<CR>", { silent = true })

-- Window resizing
map("n", "<Leader>=", ':exe "resize " . (winheight(0) * 3/2)<CR>', { silent = true })
map("n", "<Leader>-", ':exe "resize " . (winheight(0) * 2/3)<CR>', { silent = true })

-- Quick vimrc editing
map("n", "<leader>v", ":tabedit ~/.config/nvim/init.lua<CR>", { silent = true })
map("n", "<leader>V", ":tabedit ~/.config/nvim/lua/init.lua<CR>", { silent = true })

-- GitHub link in visual mode (converted from original vimfunc)
local function github_link()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local path = vim.fn.resolve(vim.fn.expand("%:p"))
	local dir = vim.fn.shellescape(vim.fn.fnamemodify(path, ":h"))

	local repo = vim.fn
		.system(
			string.format(
				"cd %s && git remote -v | awk '{ tmp = match($2, /github/); if (tmp) { split($2,a,/github.com[:\\.]/); c = a[2]; split(c,b,/[.]/); print b[1]; exit; }}'",
				dir
			)
		)
		:gsub("%s+$", "")

	local root = vim.fn.system(string.format("cd %s && git rev-parse --show-toplevel", dir)):gsub("%s+$", "")
	local relative = string.sub(path, string.len(root) - 1)
	local repo_sha = vim.fn.system(string.format("cd %s && git rev-parse HEAD", dir)):gsub("%s+$", "")

	local link =
		string.format("https://github.com/%s/blob/%s%s#L%d-L%d", repo, repo_sha, relative, start_line, end_line)

	vim.fn.setreg("+", link)
	vim.fn.setreg("*", link)
	print(link)
end

map("v", "<leader>g", github_link, { silent = true })
