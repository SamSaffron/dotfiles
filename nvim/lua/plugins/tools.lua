return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		keys = {
			{ "<C-p>", "<cmd>Telescope find_files theme=ivy disable_devicons=true<CR>" },
			{ "<leader>ff", "<cmd>Telescope find_files<CR>" },
			{ "<leader>fg", "<cmd>Telescope live_grep<CR>" },
			{ "<leader>fb", "<cmd>Telescope buffers<CR>" },
			{ "<leader>fh", "<cmd>Telescope help_tags<CR>" },
		},
		config = function()
			require("telescope").setup({
				defaults = {
					file_ignore_patterns = { "node_modules", "tmp", "log" },
				},
			})
		end,
	},
	{
		"mileszs/ack.vim",
		cmd = "Ack",
		init = function()
			vim.g.ackprg = "ag --nogroup --nocolor --column"
		end,
	},
}
