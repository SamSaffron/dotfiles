return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			words = { enabled = true },
			notifier = { enabled = true },
			bigfile = { enabled = true },
			debug = { enabled = true },
		},
    -- stylua: ignore
    keys = {
      { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    },
	},
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			require("gruvbox").setup({
				contrast = "hard",
				italic = {
					strings = false,
					comments = false,
					emphasis = false,
				},
			})
			vim.cmd.colorscheme("gruvbox")
		end,
	},
	{
		"uga-rosa/ccc.nvim",
		config = function()
			require("ccc").setup({
				highlighter = {
					auto_enable = true,
					lsp = true,
				},
			})
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = false,
		config = function()
			require("nvim-web-devicons").setup({
				color_icons = true,
				default = true,
				strict = true,
				variant = "dark",
				override = (function()
					-- technically we need to also fix the name, so
					-- rake is now white, but Rb is red
					local files = { "rb", "rakefile", "Gemfile", "Brewfile" }
					local result = {}
					for _, ext in ipairs(files) do
						result[ext] = {
							icon = "",
							color = "#bb2222",
							cterm_color = "52",
							name = "Rb",
						}
					end
					return result
				end)(),
			})
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		lazy = false,
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
		keys = {
			{
				"<leader>f",
				function()
					require("neo-tree.command").execute({
						action = "show",
						reveal = true,
					})
				end,
				desc = "Find current file",
			},
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup()
		end,
	},
}
