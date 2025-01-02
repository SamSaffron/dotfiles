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
		"cuducos/yaml.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim", -- optional
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local old_position
			local old_result

			local function get_yaml_key()
				if vim.bo.filetype ~= "yaml" then
					return ""
				end

				local position = vim.api.nvim_win_get_cursor(0)

				if old_position and old_position[1] == position[1] and old_position[2] == position[2] then
					return old_result
				end

				local result = require("yaml_nvim").get_yaml_key()

				old_position = position
				old_result = result

				return result or ""
			end
			require("lualine").setup({
				sections = {
					lualine_x = { get_yaml_key, "encoding", "fileformat", "filetype" },
				},
			})
		end,
	},
}
