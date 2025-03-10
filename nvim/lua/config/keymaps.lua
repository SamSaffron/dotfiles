local map = vim.keymap.set

-- General mappings
map("n", "<F12>", ":set number!<CR>", { desc = "Toggle line numbers" })
map("n", "<C-TAB>", ":tabnext<CR>", { desc = "Go to next tab" })
map("n", "<C-S-TAB>", ":tabprevious<CR>", { desc = "Go to previous tab" })
map("n", "<F9>", ":previous<CR>", { desc = "Go to previous buffer" })
map("n", "<F10>", ":next<CR>", { desc = "Go to next buffer" })

-- Leader mappings
map("n", "<leader>s", ":!touch tmp/refresh_browser<CR><CR>", { desc = "Touch browser refresh file" })
map("n", "<leader>g", ":silent Git gui<CR><CR>", { desc = "Open Git GUI" })
map("n", "<leader>m", "<Plug>(git-messenger)", { desc = "Show Git message" })
map("n", "<leader>l", function()
	if vim.o.hlsearch and vim.v.hlsearch == 1 then
		return ":nohls<CR>"
	else
		return ":set hls<CR>"
	end
end, { expr = true, silent = true, desc = "Toggle search highlighting" })

-- Window navigation (Alt + Arrow keys)
map("n", "<A-Up>", ":wincmd k<CR>", { desc = "Move to window above" })
map("n", "<A-Down>", ":wincmd j<CR>", { desc = "Move to window below" })
map("n", "<A-Left>", ":wincmd h<CR>", { desc = "Move to window left" })
map("n", "<A-Right>", ":wincmd l<CR>", { desc = "Move to window right" })

-- Window resizing
map("n", "<Leader>=", ':exe "resize " . (winheight(0) * 3/2)<CR>', { desc = "Increase window height" })
map("n", "<Leader>-", ':exe "resize " . (winheight(0) * 2/3)<CR>', { desc = "Decrease window height" })

-- GitHub link in visual mode (converted from original vimfunc)
local function github_link()
	local start_pos = vim.fn.getpos("v")
	local start_line = start_pos[2]
	local end_line = vim.api.nvim_win_get_cursor(0)[1]

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
	local relative = string.sub(path, string.len(root) + 2)
	local repo_sha = vim.fn.system(string.format("cd %s && git rev-parse HEAD", dir)):gsub("%s+$", "")

	local link =
		string.format("https://github.com/%s/blob/%s/%s#L%d-L%d", repo, repo_sha, relative, start_line, end_line)

	vim.fn.setreg("+", link)
	vim.fn.setreg("*", link)
	print(link)
end

map("v", "<leader>g", github_link, { desc = "Copy GitHub permalink to clipboard" })

local function restart_discourse()
	local pid_file = "/home/sam/Source/discourse/tmp/pids/unicorn.pid"

	-- Check if pid file exists
	local f = io.open(pid_file, "r")
	if f == nil then
		vim.notify("ERROR: unicorn not started")
		return
	end
	f:close()

	-- Execute the HUP signal
	vim.fn.system(string.format("kill -HUP $(cat %s)", pid_file))
	vim.notify("Restarting Discourse...")
end

map("n", "<leader>d", restart_discourse, { desc = "Restart Discourse server" })
